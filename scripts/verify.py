#!/usr/bin/env python3
"""Run evaluation, package builds and explicitly selected system builds, without switch."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["eval", "checks", "packages", "systems", "all"])
    parser.add_argument("--host", action="append", choices=["nixos", "macbook-air", "nixos-wsl", "mac-config", "home"], default=[])
    parser.add_argument("--system", default=None, help="Target Nix system (default: currentSystem)")
    parser.add_argument("--desktop", action="store_true")
    parser.add_argument("--package", action="append", default=[], help="Package output name; repeat to select affected packages")
    parser.add_argument("--minecraft", action="store_true", help="Run persistence tests; requires local MOD archives registered in the store")
    args = parser.parse_args()
    if args.stage in ("systems", "all") and not args.host:
        parser.error("systems/all requires --host; build targets are never inferred")
    system = args.system or subprocess.check_output(["nix", "eval", "--impure", "--raw", "--expr", "builtins.currentSystem"], text=True).strip()
    if system not in ("x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"):
        parser.error("unsupported system")
    nixos_hosts = {"nixos", "macbook-air", "nixos-wsl"}
    if any(h in nixos_hosts for h in args.host) and system != "x86_64-linux":
        parser.error("the configured NixOS hosts use x86_64-linux")
    if "mac-config" in args.host and not system.endswith("-darwin"):
        parser.error("mac-config requires a Darwin target")
    if args.minecraft and system != "x86_64-linux":
        parser.error("Minecraft persistence tests run on x86_64-linux")

    def run(*command, cwd=ROOT):
        print("+ " + " ".join(map(str, command)), flush=True)
        subprocess.run(command, cwd=cwd, check=True)

    with tempfile.TemporaryDirectory(prefix="nix-verify-") as directory:
        options = Path(directory) / "options.nix"
        options.write_text('{ username = "nix-test"; isDesktop = ' + str(args.desktop).lower() + '; system = ' + json.dumps(system) + '; }\n')
        flags = ["--no-write-lock-file", "--override-input", "local-options", "path:" + str(options)]
        root = "path:" + str(ROOT)
        # Every build stage starts by checking the selected evaluation.
        run("nix", "flake", "check", "--no-build", root, *flags)
        run("nix", "eval", "--raw", f"{root}#homeConfigurations.myHomeConfig.activationPackage.drvPath", *flags)
        if system.endswith("-darwin"):
            run("nix", "eval", "--raw", f"{root}#darwinConfigurations.mac-config.system.drvPath", *flags)
        if args.stage in ("checks", "all"):
            run("nix", "flake", "check", root, *flags)
        if args.stage in ("packages", "all"):
            packages = args.package or ["bash-abbrev-alias", "keifu", "filetree", "takt"]
            if args.desktop and system == "x86_64-linux" and not args.package:
                packages += ["chatgpt", "orca-ide", "ghostty-wayland-ime"]
            run("nix", "build", "--no-link", *[f"{root}#packages.{system}.{p}" for p in packages], *flags)
        if args.stage in ("systems", "all"):
            for host in args.host:
                if host == "home":
                    output = "homeConfigurations.myHomeConfig.activationPackage"
                elif host == "mac-config":
                    output = "darwinConfigurations.mac-config.system"
                else:
                    output = f"nixosConfigurations.{host}.config.system.build.toplevel"
                run("nix", "build", "--no-link", f"{root}#{output}", *flags)
        if args.minecraft:
            run(sys.executable, ROOT / "flakes/minecraft/tests/test_prismix_persistence.py")


if __name__ == "__main__":
    main()
