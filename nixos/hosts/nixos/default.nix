{ ... }:
{
  imports = [
    ../../hardware-configuration.nix
    ../../system/hardware.nix
  ];
  networking.hostName = "nixos";
  system.stateVersion = "25.05";
}
