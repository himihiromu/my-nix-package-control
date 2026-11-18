{ username, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ../../system/mount-failure-notifications.nix
  ];
  home-manager.users.${username}.imports = [ ../../../home-manager/hosts/nixos/monitors.nix ];
  networking.hostName = "nixos";
  system.stateVersion = "25.05";
}
