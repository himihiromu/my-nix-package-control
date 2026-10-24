{ username, ... }:

{
  users.users.${username}.extraGroups = [ "networkmanager" ];
  networking.firewall = {
    allowedTCPPorts = [
      6768 # Orca mobile (WebSocket)
      53317
    ];
    allowedUDPPorts = [ 53317 ];
  };

  # NetworkManager
  networking.networkmanager.enable = true;

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
