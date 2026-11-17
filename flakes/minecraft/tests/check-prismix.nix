# Standalone compatibility entry for Python persistence tests.
import ./fixture.nix { flake = builtins.getFlake ("path:" + toString ../.); }
