{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./macbook-hardware.nix
  ];

  networking.hostName = "macbook-air";
  system.stateVersion = "26.05";

  # This MacBook has a single ESP mounted at /boot, without XBOOTLDR.
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    timeout = 5;
  };

  fileSystems."/".options = [ "compress=zstd" "noatime" ];
  fileSystems."/home".options = [ "compress=zstd" "noatime" ];
  fileSystems."/nix".options = [ "compress=zstd" "noatime" ];

  console.keyMap = "jp106";
  services.xserver.xkb = {
    layout = "jp";
    model = "jp106";
  };

  # Handle the JIS Kana/Eisu keys before Mozc: Eisu must deactivate
  # Fcitx rather than leave Mozc enabled in its internal Direct mode.
  i18n.inputMethod.fcitx5.settings.globalOptions = {
    "Hotkey/TriggerKeys" = {
      "0" = "Control+space";
      "1" = "Zenkaku_Hankaku";
    };
    "Hotkey/ActivateKeys" = {
      "0" = "Hangul";
      "1" = "Hiragana_Katakana";
    };
    "Hotkey/DeactivateKeys" = {
      "0" = "Hangul_Hanja";
      "1" = "Eisu_toggle";
    };
  };

  # Fcitx 5.1.21 forwards ActivateKeys to Mozc when already active,
  # allowing Kana to toggle Mozc back to Direct. Consume both keys in
  # Hyprland instead, even when the requested state is already selected.
  # This Apple JIS keyboard emits XKB codes 130 (Kana) and 131 (Eisu),
  # seen by Fcitx as Hangul and Hangul_Hanja. Bind the physical codes
  # independently of the input method's current keyboard layout.
  home-manager.users.himihiromu.wayland.windowManager.hyprland.settings.bind = [
    ", code:130, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -o"
    ", code:131, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -c"
    ", Hiragana_Katakana, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -o"
    ", Eisu_toggle, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -c"
  ];
  security.rtkit.enable = true;

  # Keep builds within the memory available on this 8 GB machine.
  nix.settings.max-jobs = 1;
  nix.settings.cores = 2;
}
