{ ... }:
{
  imports = [
    ../../hardware-configuration.nix
    ../../system/hardware.nix
    ../../system/mount-failure-notifications.nix
  ];
  networking.hostName = "nixos";
  system.stateVersion = "25.05";
}
