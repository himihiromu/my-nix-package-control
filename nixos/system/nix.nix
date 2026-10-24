{
  config,
  username,
  lib,
  ...
}:

{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "zsh-abbr"
      "claude-code"
      "vscode"
      "google-chrome"
      "zoom"
      "discord"
      "discord-unwrapped"
      "steam"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
      "discord-unwrapped"
    ];

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
