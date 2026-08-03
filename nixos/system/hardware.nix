{ config, pkgs, ... }:

{
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

  # Latest stable kernel
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Redistributable Firmware
  hardware.enableRedistributableFirmware = true;
}
