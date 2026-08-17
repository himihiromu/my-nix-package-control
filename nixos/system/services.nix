{ config, pkgs, ... }:

{
  # NetworkManager
  networking.networkmanager.enable = true;

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    rootless.enable = true;
  };

  # systemd-timesyncd
  services.timesyncd.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Bluetooth device manager
  services.blueman.enable = true;

  # Gaming mouse configuration daemon (libratbag)
  services.ratbagd.enable = true;

  # Avahi
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
