"""生成された activation 断片のみを一時 HOME で実行する。switch は行わない。"""
import configparser
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
FIXTURE = REPO / "tests/check-prismix.nix"


def metadata(attribute):
    return json.loads(subprocess.check_output(
        ["nix", "eval", "--impure", "--json", "--file", str(FIXTURE), attribute],
        cwd=REPO, text=True,
    ))


class PersistenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        subprocess.run([
            "nix", "build", "--impure", "--file", str(FIXTURE),
            "activationPackage", "updatedFiles", "--no-link",
        ], cwd=REPO, check=True)
        cls.current = metadata("metadata")
        cls.updated = metadata("updatedMetadata")

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="prismix-persistence-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / "home"
        self.home.mkdir()
        self.data = self.home / ".local/share/PrismLauncher"
        self.instance = self.data / "instances/Vanilla"
        self.saves = self.instance / "minecraft/saves"

    def shell(self, script, data):
        script = script.replace(data["homeDirectory"], str(self.home))
        return subprocess.run(
            ["bash", "-c", 'set -e\nrun() { "$@"; }\nVERBOSE_ARG=\n' + script],
            cwd=self.home, text=True, capture_output=True,
        )

    def apply_fragments(self, data):
        for key in ("checkScript", "legacyCheckScript", "modernCheckScript", "createScript", "legacySeedScript", "modernSeedScript"):
            result = self.shell(data[key], data)
            self.assertEqual(result.returncode, 0, result.stderr)
        for target, file in data["files"].items():
            path = Path(target.replace(data["homeDirectory"], str(self.home)))
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.is_symlink():
                path.unlink()  # 一時 HOME 内の生成用 .hm_* リンクのみ更新する。
            path.symlink_to(file["source"])
        for file in data["files"].values():
            result = self.shell(file["onChange"], data)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_generation_reapply_and_version_change_preserve_user_data(self):
        self.data.mkdir(parents=True)
        (self.data / "prismlauncher.cfg").write_text("[General]\nCustomSetting=keep\n")
        account = self.data / "accounts.json"
        account.write_text('{"test-placeholder": true}')
        other = self.data / "instances/Other/minecraft/saves/Existing/level.dat"
        other.parent.mkdir(parents=True)
        other.write_bytes(b"other-world-sentinel")
        self.apply_fragments(self.current)

        pack = json.loads((self.instance / "mmc-pack.json").read_text())
        self.assertEqual(pack["components"], [{
            "uid": "net.minecraft", "version": "26.3", "important": True,
        }])
        ini = configparser.ConfigParser()
        ini.read(self.instance / "instance.cfg")
        settings = ini["General"]
        self.assertEqual(settings["name"], "Vanilla")
        self.assertEqual(settings["JavaPath"], self.current["java"])
        self.assertTrue(settings.getboolean("OverrideJavaLocation"))
        self.assertTrue(settings.getboolean("OverrideMemory"))
        self.assertEqual(settings.getint("MinMemAlloc"), 1024)
        self.assertEqual(settings.getint("MaxMemAlloc"), 4096)
        for path in (self.instance, self.instance / "minecraft", self.saves):
            self.assertFalse(path.is_symlink())
        self.assertFalse((self.instance / "instance.cfg").is_symlink())
        self.assertFalse((self.instance / "mmc-pack.json").is_symlink())

        # 実ゲームの NBT ではなく、再適用による消失・破損を検出する保存データ。
        world = self.saves / "Test World/level.dat"
        world.parent.mkdir()
        world.write_bytes(b"world-sentinel\x00\xff")
        options = self.instance / "minecraft/options.txt"
        options.write_text("unmanaged-setting:keep\n")
        for data in (self.current, self.updated):
            self.apply_fragments(data)
            self.assertEqual(world.read_bytes(), b"world-sentinel\x00\xff")
            self.assertEqual(other.read_bytes(), b"other-world-sentinel")
            self.assertEqual(options.read_text(), "unmanaged-setting:keep\n")
            self.assertEqual(account.read_text(), '{"test-placeholder": true}')
            self.assertIn("CustomSetting=keep", (self.data / "prismlauncher.cfg").read_text())
        self.assertEqual(json.loads((self.instance / "mmc-pack.json").read_text())["components"][0]["version"], "26.2")

    def test_unmanaged_vanilla_is_rejected_without_changes(self):
        self.saves.mkdir(parents=True)
        config = self.instance / "instance.cfg"
        config.write_bytes(b"existing-instance")
        world = self.saves / "level.dat"
        world.write_bytes(b"existing-world")
        result = self.shell(self.current["checkScript"], self.current)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(config.read_bytes(), b"existing-instance")
        self.assertEqual(world.read_bytes(), b"existing-world")
        self.assertFalse((self.instance / ".hm_instance.cfg").exists())

    def test_symlinked_saves_and_config_are_rejected(self):
        self.apply_fragments(self.current)
        outside = Path(self.tmp.name) / "outside"
        outside.mkdir()
        sentinel = outside / "level.dat"
        sentinel.write_bytes(b"protected")
        self.saves.rmdir()  # テストで作成した空ディレクトリのみ。
        self.saves.symlink_to(outside, target_is_directory=True)
        result = self.shell(self.current["checkScript"], self.current)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(sentinel.read_bytes(), b"protected")
        self.saves.unlink()
        self.saves.mkdir()
        config = self.instance / "instance.cfg"
        config.unlink()
        config.symlink_to(sentinel)
        result = self.shell(self.current["checkScript"], self.current)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(sentinel.read_bytes(), b"protected")

    def test_legacy_worlds_and_edited_configs_survive_reapply(self):
        self.apply_fragments(self.current)
        instance = self.data / "instances/Industry-Magic-1.7.10-Trial"
        world = instance / "minecraft/saves/Restored World/level.dat"
        world.parent.mkdir()
        world.write_bytes(b"restored-world")
        cfg = instance / "minecraft/config/aroma1997/AromaBackup.cfg"
        cfg.write_text("user-edited-config\n")
        options = instance / "minecraft/options.txt"
        options.write_text("user-edited-options\n")
        self.apply_fragments(self.updated)
        self.assertEqual(world.read_bytes(), b"restored-world")
        self.assertEqual(cfg.read_text(), "user-edited-config\n")
        self.assertEqual(options.read_text(), "user-edited-options\n")
        self.assertFalse(cfg.is_symlink())
        pack = json.loads((instance / "mmc-pack.json").read_text())
        components = {c["uid"]: c["version"] for c in pack["components"]}
        self.assertEqual(components["net.minecraftforge"], "10.13.4.1614")

    def test_legacy_mod_changes_and_symlinked_saves_are_rejected(self):
        self.apply_fragments(self.current)
        instance = self.data / "instances/Industrial-1.7.10-Trial"
        mod = next((instance / "minecraft/mods").glob("*.jar"))
        original = mod.read_bytes()
        mod.write_bytes(b"modified-mod")
        result = self.shell(self.current["legacyCheckScript"], self.current)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(mod.read_bytes(), b"modified-mod")
        mod.write_bytes(original)
        saves = instance / "minecraft/saves"
        saves.rmdir()
        outside = Path(self.tmp.name) / "outside-legacy"
        outside.mkdir()
        saves.symlink_to(outside, target_is_directory=True)
        result = self.shell(self.current["legacyCheckScript"], self.current)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(outside.iterdir()), [])

    def test_legacy_existing_instance_is_adopted_with_settings_backup(self):
        self.apply_fragments(self.current)
        instance = self.data / "instances/Industry-Magic-1.7.10-Trial"
        for name in ("instance.cfg", "mmc-pack.json"):
            (instance / (".hm_" + name)).unlink()
        cfg = instance / "instance.cfg"
        cfg.write_text(cfg.read_text() + "\n[Custom]\nkeep=yes\n")
        before = cfg.read_bytes()
        world = instance / "minecraft/saves/Existing/level.dat"
        world.parent.mkdir()
        world.write_bytes(b"existing-legacy-world")
        self.apply_fragments(self.current)
        self.assertEqual((instance / ".legacy-before-nix/instance.cfg").read_bytes(), before)
        self.assertIn("keep=yes", cfg.read_text())
        self.assertEqual(world.read_bytes(), b"existing-legacy-world")

    def test_legacy_wrong_version_is_not_adopted(self):
        instance = self.data / "instances/Industry-Magic-1.7.10-Trial"
        instance.mkdir(parents=True)
        pack = instance / "mmc-pack.json"
        pack.write_text(json.dumps({"components": [{"uid": "net.minecraft", "version": "1.12.2"}]}))
        (instance / "instance.cfg").write_text("[General]\nInstanceType=OneSix\n")
        before = pack.read_bytes()
        result = self.shell(self.current["legacyCheckScript"], self.current)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(pack.read_bytes(), before)
        self.assertFalse((instance / ".legacy-before-nix").exists())

    def test_existing_modern_instance_with_lwjgl3_is_adopted(self):
        self.apply_fragments(self.current)
        instance = self.data / "instances/Industry-Magic-1.20.1"
        for name in ("instance.cfg", "mmc-pack.json"):
            (instance / (".hm_" + name)).unlink()
        pack_path = instance / "mmc-pack.json"
        pack = json.loads(pack_path.read_text())
        pack["components"].insert(0, {
            "uid": "org.lwjgl3", "version": "3.3.1", "dependencyOnly": True,
        })
        pack_path.write_text(json.dumps(pack))
        before_pack = pack_path.read_bytes()
        cfg = instance / "instance.cfg"
        cfg.write_text(cfg.read_text() + "\n[Custom]\nkeep=yes\n")
        before_cfg = cfg.read_bytes()
        world = instance / "minecraft/saves/Existing/level.dat"
        world.parent.mkdir()
        world.write_bytes(b"existing-modern-world")
        options = instance / "minecraft/options.txt"
        options.write_text("user-options\n")
        self.apply_fragments(self.current)
        self.assertEqual((instance / ".legacy-before-nix/mmc-pack.json").read_bytes(), before_pack)
        self.assertEqual((instance / ".legacy-before-nix/instance.cfg").read_bytes(), before_cfg)
        self.assertIn("keep=yes", cfg.read_text())
        self.assertEqual(world.read_bytes(), b"existing-modern-world")
        self.assertEqual(options.read_text(), "user-options\n")

    def test_existing_modern_unknown_component_or_wrong_version_is_rejected(self):
        instance = self.data / "instances/Industry-Magic-1.20.1"
        instance.mkdir(parents=True)
        (instance / "instance.cfg").write_text("[General]\nInstanceType=OneSix\n")
        pack_path = instance / "mmc-pack.json"
        for extra, minecraft, forge, error in [
            ([{"uid": "unknown.loader", "version": "1"}], "1.20.1", "47.4.28", "unknown.loader"),
            ([], "1.20.2", "47.4.28", "Minecraft/Forge"),
            ([], "1.20.1", "47.4.0", "Minecraft/Forge"),
        ]:
            with self.subTest(extra=extra, minecraft=minecraft, forge=forge):
                pack_path.write_text(json.dumps({"components": [
                    {"uid": "org.lwjgl3", "version": "3.3.1", "dependencyOnly": True},
                    {"uid": "net.minecraft", "version": minecraft},
                    {"uid": "net.minecraftforge", "version": forge},
                ] + extra}))
                before = pack_path.read_bytes()
                result = self.shell(self.current["modernCheckScript"], self.current)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stderr)
                self.assertEqual(pack_path.read_bytes(), before)
                self.assertFalse((instance / ".legacy-before-nix").exists())

    def test_modern_pack_versions_and_worlds_survive_reapply(self):
        self.apply_fragments(self.current)
        instance = self.data / "instances/Industry-Magic-1.20.1"
        pack = json.loads((instance / "mmc-pack.json").read_text())
        versions = {component["uid"]: component["version"] for component in pack["components"]}
        self.assertEqual(versions["net.minecraft"], "1.20.1")
        self.assertEqual(versions["net.minecraftforge"], "47.4.28")
        jars = list((instance / "minecraft/mods").glob("*.jar"))
        self.assertEqual(len(jars), 48)
        self.assertFalse(any("touhoulittlemaid" in jar.name for jar in jars))
        self.assertFalse(any(jar.is_symlink() for jar in jars))
        options = instance / "minecraft/options.txt"
        self.assertIn("lang:ja_jp", options.read_text())
        options.write_text("user-options\n")
        world = instance / "minecraft/saves/Modern/level.dat"
        world.parent.mkdir()
        world.write_bytes(b"modern-world")
        self.apply_fragments(self.updated)
        self.assertEqual(world.read_bytes(), b"modern-world")
        self.assertEqual(options.read_text(), "user-options\n")


if __name__ == "__main__":
    unittest.main()
