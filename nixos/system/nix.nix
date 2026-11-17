{
  config,
  username,
  lib,
  ...
}:

{
  nixpkgs.config = import ../../lib/nixpkgs-policy.nix {
    inherit lib;
    extraAllowedNames = [ "steam" "steam-original" "steam-unwrapped" "steam-run" ];
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [
      username
    ];

    substituters = [
      "https://cache.nixos.org"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = "weekly";
  };
}
