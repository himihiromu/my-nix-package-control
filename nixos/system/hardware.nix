{ config, pkgs, ... }:

{
  # Windows NTFS volumes shared with NixOS.
  fileSystems = {
    # D: Shared data drive
    "/mnt/shared" = {
      device = "/dev/disk/by-uuid/6444A92E44A903C0";
      fsType = "ntfs3";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "fmask=0133"
        "dmask=0022"
        "windows_names"
        "noatime"
        "nofail"
        "x-systemd.automount"
      ];
    };

    # H: TOSHIBA HDD
    "/mnt/games/hdd" = {
      device = "/dev/disk/by-uuid/3AFEB55DFEB511DD";
      fsType = "ntfs3";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "fmask=0022"
        "dmask=0022"
        "windows_names"
        "noatime"
        "nofail"
        "x-systemd.automount"
      ];
    };

    # F: Samsung SATA SSD
    "/mnt/games/ssd" = {
      device = "/dev/disk/by-uuid/DABC9520BC94F7E9";
      fsType = "ntfs3";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "fmask=0022"
        "dmask=0022"
        "windows_names"
        "noatime"
        "nofail"
        "x-systemd.automount"
      ];
    };

    # J: Nextorage NVMe SSD
    "/mnt/games/nvme" = {
      device = "/dev/disk/by-uuid/1C7E75C67E7598EA";
      fsType = "ntfs3";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "fmask=0022"
        "dmask=0022"
        "windows_names"
        "noatime"
        "nofail"
        "x-systemd.automount"
      ];
    };
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
      rebootForBitlocker = false;
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
