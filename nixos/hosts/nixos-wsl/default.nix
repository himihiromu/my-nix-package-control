# WSL2 on Windows
{ ... }:
{
  system.stateVersion = "24.05";
  wsl.enable = true;

  # SSH server. Native systemd is always enabled on current NixOS-WSL,
  # so sshd runs like on bare metal. The NixOS-WSL module disables the
  # in-guest firewall service, so no openFirewall is needed here.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
