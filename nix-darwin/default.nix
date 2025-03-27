{ pkgs, ... }:
let
#   fonts = import ./config/fonts.nix { inherit pkgs; };
#   networking = import ./config/networking.nix;
  # security = import ./config/security.nix { inherit username; };
  # services = import ./config/services;
  # time = import ./config/time.nix;
  system = import ./config/system.nix { inherit pkgs; };
  homebrew = import ./config/homebrew.nix { inherit pkgs; };
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
    system
    # time
  ];
  system.stateVersion = 4;
}
