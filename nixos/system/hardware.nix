{ config, pkgs, ... }:

{
  # Windows Steam library (J:). Keep Proton prefixes on the Linux filesystem.
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/1C7E75C67E7598EA";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "windows_names"
      "noatime"
    ];
  };

  # UEFI boot loader with separate XBOOTLDR and ESP partitions.
  boot.loader = {
    grub.enable = false;
    systemd-boot = {
      enable = true;
      configurationLimit = 3;

      # Kernel/initrd/boot entries are stored on the XBOOTLDR partition.
      xbootldrMountPoint = "/boot";

      # Reboot through the firmware Windows Boot Manager instead of
      # directly chainloading Windows.
      rebootForBitlocker = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
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
