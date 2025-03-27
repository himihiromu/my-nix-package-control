{ pkgs, username, ... }:
let
#   fonts = import ./config/fonts.nix { inherit pkgs; };
#   networking = import ./config/networking.nix;
  # security = import ./config/security.nix { inherit username; };
  # services = import ./config/services;
  # time = import ./config/time.nix;
  nix = import ./config/nix.nix { inherit pkgs; };
  system = import ./config/system.nix { inherit pkgs; };
  homebrew = import ./config/homebrew.nix { inherit pkgs; };
in
{
  imports = [
    # fonts
    homebrew
    # networking
    nix
    # security
    # services
    system
    # time
  ];
}
