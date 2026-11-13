"""ローカルの旧MOD資産を固定し、セーブを触らずにPrism環境を初期化する。"""
import argparse
import configparser
import gzip
import hashlib
import io
import json
from pathlib import Path
import shutil
import subprocess
import tarfile


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def regular(path):
    if path.is_symlink() or (path.exists() and not path.is_file()):
        raise ValueError(f"通常ファイルではありません: {path}")


def directory(path):
    if path.is_symlink() or (path.exists() and not path.is_dir()):
        raise ValueError(f"通常ディレクトリではありません: {path}")


def asset_path(base, name):
    relative = Path(name)
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"不正な相対パス: {name}")
    current = base
    directory(current)
    for part in relative.parts[:-1]:
        current = current / part
        directory(current)
    result = base / relative
    regular(result)
    return result


def write_archive(spec, source, output):
    """時刻・所有者・並び順・gzipヘッダを固定する。セーブ等はmanifestに含めない。"""
    for name, expected in spec["files"].items():
        path = asset_path(source, name)
        if digest(path) != expected:
            raise ValueError(f"元資産のハッシュが一致しません: {path}")
    with output.open("wb") as raw:
        with gzip.GzipFile(fileobj=raw, mode="wb", filename="", mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.GNU_FORMAT) as archive:
                for name in sorted(spec["files"]):
                    path = source / name
                    info = tarfile.TarInfo(name)
                    info.size = path.stat().st_size
                    info.mode = 0o644
                    with path.open("rb") as stream:
                        archive.addfile(info, stream)


def cache(manifest, source_root, cache_dir):
    cache_dir.mkdir(parents=True, exist_ok=True)
    for spec in manifest.values():
        output = cache_dir / spec["archiveName"]
        if not output.exists() or digest(output) != spec["archiveSha256"]:
            temporary = output.with_suffix(".tmp")
            write_archive(spec, source_root / spec["sourceDirectory"], temporary)
            if digest(temporary) != spec["archiveSha256"]:
                raise ValueError(f"アーカイブのハッシュが一致しません: {temporary}")
            temporary.replace(output)
        subprocess.run(["nix-store", "--add-fixed", "sha256", str(output)], check=True)
        print(f"Nix Storeへ登録しました: {output.name}", flush=True)


def check_instance(root, instance_id, spec):
    instance = root / "instances" / instance_id
    game = instance / "minecraft"
    for process in Path("/proc").glob("[0-9]*"):
        try:
            if (process / "comm").read_text().strip() == "java" and (process / "cwd").resolve() == game:
                raise ValueError(f"Minecraftを終了してから適用してください: {instance_id}")
        except (OSError, RuntimeError):
            pass
    for path in (root, root / "instances", instance, game, game / "saves", game / "mods", game / "config"):
        directory(path)
    old = instance / ".minecraft"
    if old.exists() or old.is_symlink():
        raise ValueError(f"旧形式のゲームディレクトリは自動変更しません: {old}")
    for name in ("instance.cfg", "mmc-pack.json", ".legacy-assets.json"):
        regular(instance / name)
    directory(instance / ".legacy-before-nix")
    for name in ("instance.cfg", "mmc-pack.json"):
        regular(instance / ".legacy-before-nix" / name)
    asset_path(game, "options.txt")
    # 今回作成したインスタンスの版を照合してから管理へ取り込む。
    # 他の同名インスタンスにForgeを強制しない。
    if instance.exists() and not (instance / ".hm_mmc-pack.json").is_symlink():
        pack = instance / "mmc-pack.json"
        cfg = instance / "instance.cfg"
        if not pack.is_file() or not cfg.is_file():
            raise ValueError(f"既存インスタンスを特定できません: {instance}")
        components = {c["uid"]: c["version"] for c in json.loads(pack.read_text())["components"]}
        if components.get("net.minecraft") != spec.get("minecraftVersion", "1.7.10") or components.get("net.minecraftforge") != spec.get("forgeVersion", "10.13.4.1614"):
            raise ValueError(f"既存インスタンスのMinecraft/Forgeの版が違います: {instance}")
        if set(components) - {"net.minecraft", "net.minecraftforge", "org.lwjgl"}:
            raise ValueError(f"未確認の追加コンポーネントがあります: {instance}")
        ini = configparser.ConfigParser(interpolation=None)
        ini.read(cfg)
        if ini.get("General", "InstanceType", fallback="") != "OneSix":
            raise ValueError(f"未対応のインスタンス形式: {instance}")
    for name, expected in spec["files"].items():
        path = asset_path(game, name)
        if name.startswith("mods/") and path.exists() and digest(path) != expected:
            raise ValueError(f"既存MODが固定構成と異なります: {path}")
    if (game / "mods").exists():
        for path in (game / "mods").rglob("*"):
            if path.is_symlink():
                raise ValueError(f"MOD内のリンクは変更しません: {path}")
            if path.is_file() and path.suffix.lower() in (".jar", ".zip"):
                if path.relative_to(game).as_posix() not in spec["files"]:
                    raise ValueError(f"未管理の追加MODがあります: {path}")


def seed(root, manifest, assets):
    # 全インスタンスの事前検査を終えてから書き込む。
    for instance_id, spec in manifest.items():
        check_instance(root, instance_id, spec)
        for name, expected in spec["files"].items():
            if digest(asset_path(assets / instance_id, name)) != expected:
                raise ValueError(f"固定資産のハッシュが一致しません: {instance_id}/{name}")
    for instance_id, spec in manifest.items():
        instance = root / "instances" / instance_id
        game = instance / "minecraft"
        instance.mkdir(parents=True, exist_ok=True)
        # 取り込み前のランチャー設定だけを保管する。ワールドには触れない。
        if not (instance / ".hm_mmc-pack.json").is_symlink():
            backup = instance / ".legacy-before-nix"
            directory(backup)
            backup.mkdir(exist_ok=True)
            for name in ("instance.cfg", "mmc-pack.json"):
                original = instance / name
                saved = asset_path(backup, name)
                if original.exists() and not saved.exists():
                    with original.open("rb") as inp, saved.open("xb") as out:
                        shutil.copyfileobj(inp, out)
        for name in spec["files"]:
            target = asset_path(game, name)
            if not target.exists():
                target.parent.mkdir(parents=True, exist_ok=True)
                with (assets / instance_id / name).open("rb") as inp, target.open("xb") as out:
                    shutil.copyfileobj(inp, out)
        (game / "saves").mkdir(parents=True, exist_ok=True)
        options = asset_path(game, "options.txt")
        if not options.exists():
            with options.open("x") as stream:
                stream.write("lang:" + spec.get("language", "ja_JP") + "\nrenderDistance:8\n")
        (instance / ".legacy-assets.json").write_text(json.dumps({
            "archive": spec["archiveName"], "sha256": spec["archiveSha256"],
        }, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("cache", "check", "seed"))
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--data-dir", type=Path)
    parser.add_argument("--assets", type=Path)
    parser.add_argument("--source-root", type=Path, default=Path("/mnt/minecraft/マインクラフト　ファイル"))
    parser.add_argument("--cache-dir", type=Path, default=Path.home() / ".cache/minecraft-legacy")
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())
    try:
        if args.action == "cache":
            cache(manifest, args.source_root, args.cache_dir)
        else:
            if args.data_dir is None:
                parser.error("--data-dir is required")
            if args.action == "check":
                for instance_id, spec in manifest.items():
                    check_instance(args.data_dir, instance_id, spec)
            else:
                if args.assets is None:
                    parser.error("--assets is required")
                seed(args.data_dir, manifest, args.assets)
    except (ValueError, OSError, KeyError) as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()
