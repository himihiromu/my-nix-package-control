{ ... }:
{
  # MacBookAir7,2: Broadwell i5-5250U, BCM4360 14e4:43a0.
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "bcm5974" "hid_apple" "applesmc" ];
  # 上段キー単独で明るさ・音量、Fn併用でF1〜F12を送信する。
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=1
  '';
  # Ethernet-only baseline: BCM4360 is unsupported by b43, and wl was declined.
  boot.blacklistedKernelModules = [ "wl" "b43" "b43legacy" "bcma" "ssb" "brcmsmac" ];
  hardware.bluetooth.enable = true;
  services.libinput.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fstrim.enable = true;
  services.smartd.enable = true;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
