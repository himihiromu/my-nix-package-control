{ ... }:
{
  imports = [
    ./config/homebrew
    ./config/launchd.nix
    ./config/nix-config.nix
    ./config/system.nix
  ];
  system.stateVersion = 4;
}
