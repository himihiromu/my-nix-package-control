{ pkgs, system, isDesktop, ... }:
let
#   fonts = import ./config/fonts.nix { inherit pkgs; };
#   networking = import ./config/networking.nix;
  # security = import ./config/security.nix { inherit username; };
  # services = import ./config/services;
  # time = import ./config/time.nix;
  system_config = import ./config/system.nix { inherit pkgs; inherit system; };
  homebrew = import ./config/homebrew/default.nix { inherit pkgs; inherit isDesktop;};
  nixConfig = import ./config/nix-config.nix { inherit pkgs; };

in
{
  imports = [
    # fonts
    homebrew
    # networking
    nixConfig
    # security
    # services
    system_config
    # time
  ];
  system.stateVersion = 4;
}
