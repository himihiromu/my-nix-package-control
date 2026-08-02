# NixOS Entry Point
# 設定は極力書かず、エントリーポイントとして利用する

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./system/hardware.nix
    ./system/desktop.nix
    ./system/services.nix
    ./system/nix.nix
  ];

  # Hostname
  networking.hostName = "nixos";

  # User
  users.users.himihiromu = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
    ];
  };

  # Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  system.stateVersion = "25.05";
}
