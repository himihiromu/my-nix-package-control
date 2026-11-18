"""Verify target selection, isolated inputs and failure propagation without building Nix."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class VerificationRunnerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="verify-runner-")
        self.addCleanup(self.tmp.cleanup)
        self.directory = Path(self.tmp.name)
        self.log = self.directory / "calls.jsonl"
        nix = self.directory / "nix"
        nix.write_text(f"#!{sys.executable}\n" + '''import json, os, sys
from pathlib import Path
args = sys.argv[1:]
if "--expr" in args:
    print("x86_64-linux", end="")
    sys.exit(0)
record = {"args": args, "cwd": os.getcwd()}
if "--override-input" in args:
    index = args.index("--override-input")
    record["options"] = Path(args[index + 2].removeprefix("path:")).read_text()
with open(os.environ["TEST_NIX_LOG"], "a") as stream:
    stream.write(json.dumps(record) + "\\n")
if os.environ.get("TEST_FAIL_EVAL") and "--no-build" in args:
    sys.exit(7)
''')
        nix.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.directory) + ":" + os.environ["PATH"], TEST_NIX_LOG=str(self.log))

    def run_verify(self, *args, fail=False):
        env = dict(self.env, TEST_FAIL_EVAL="1") if fail else self.env
        result = subprocess.run([sys.executable, str(ROOT / "scripts/verify.py"), *args], cwd=self.directory, env=env, capture_output=True, text=True)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []
        return result, calls

    def test_package_selection_from_unrelated_directory(self):
        result, calls = self.run_verify("packages", "--package", "chatgpt", "--desktop")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 3)
        self.assertIn("--no-build", calls[0]["args"])
        self.assertIn(f"path:{ROOT}#packages.x86_64-linux.chatgpt", calls[2]["args"])
        self.assertIn('isDesktop = true;', calls[2]["options"])
        self.assertIn('username = "nix-test";', calls[2]["options"])
        self.assertEqual(calls[2]["cwd"], str(ROOT))
        self.assertNotIn("switch", calls[2]["args"])

    def test_explicit_host_and_stage_order(self):
        result, calls = self.run_verify("all", "--host", "nixos-wsl")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 5)
        self.assertIn("--no-build", calls[0]["args"])
        self.assertEqual(calls[2]["args"][:2], ["flake", "check"])
        self.assertNotIn("--no-build", calls[2]["args"])
        self.assertIn(f"path:{ROOT}#nixosConfigurations.nixos-wsl.config.system.build.toplevel", calls[-1]["args"])

    def test_host_required_before_any_build(self):
        result, calls = self.run_verify("all")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires --host", result.stderr)
        self.assertEqual(calls, [])

    def test_evaluation_failure_stops_following_builds(self):
        result, calls = self.run_verify("all", "--host", "nixos-wsl", fail=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(calls), 1)
        self.assertIn("--no-build", calls[0]["args"])


if __name__ == "__main__":
    unittest.main()
