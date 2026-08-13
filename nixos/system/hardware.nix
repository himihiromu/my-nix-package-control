{ config, pkgs, ... }:

{
  # UEFI boot loader (the generated hardware file only defines /boot).
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
    };
    efi.canTouchEfiVariables = true;
  };

  # AMD CPU Microcode
  hardware.cpu.amd.updateMicrocode = true;

  # AMDGPU
  boot.initrd.kernelModules = [
    "amdgpu"
  ];

  # Mesa / OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Redistributable Firmware
  hardware.enableRedistributableFirmware = true;
}
