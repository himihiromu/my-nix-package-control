{ ... }:

{
  # Firewall
  networking.firewall = {
    enable = true;
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    rootless.enable = true;
  };

  # OpenSSH server
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
