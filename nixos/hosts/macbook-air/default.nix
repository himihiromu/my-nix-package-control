{ pkgs, username, ... }:
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
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.plugins = [
      (pkgs.callPackage ./hyprexpo.nix { })
    ];
    wayland.windowManager.hyprland.settings.bind = [
      ", code:130, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -o"
      ", code:131, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -c"
      ", Hiragana_Katakana, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -o"
      ", Eisu_toggle, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -c"
      # Scrolling layout: move focus between columns and change their order.
      "$mod, H, layoutmsg, focus l"
      "$mod, L, layoutmsg, focus r"
      "$mod SHIFT, H, layoutmsg, swapcol l"
      "$mod SHIFT, L, layoutmsg, swapcol r"
      "$mod, Comma, layoutmsg, colresize -conf"
      "$mod, Period, layoutmsg, colresize +conf"
      "$mod, P, layoutmsg, promote"
      "$mod SHIFT, P, layoutmsg, expel"
      "$mod CTRL, P, layoutmsg, consume_or_expel prev"
      "$mod, I, layoutmsg, fit active"
    ];
    wayland.windowManager.hyprland.settings.general = {
      layout = "scrolling";
    };
    wayland.windowManager.hyprland.settings.scrolling = {
      # Half-width columns leave adjacent windows visible as context.
      column_width = 0.5;
      fullscreen_on_one_column = true;
      focus_fit_method = 1;
      follow_focus = true;
      follow_min_visible = 0.4;
      explicit_column_widths = "0.333, 0.5, 0.667, 1.0";
      wrap_focus = true;
      wrap_swapcol = true;
      direction = "right";
    };
    wayland.windowManager.hyprland.settings.device = [
      {
        name = "bcm5974";
        # -1.0〜1.0。正の値で速く、負の値で遅くする。0.0は標準速度。
        sensitivity = 0.0;
        # スクロール量を標準の70%に抑える。
        scroll_factor = 0.7;
        # 2本指の押し込み・タップを右クリックにする。
        clickfinger_behavior = true;
        tap-to-click = true;
        tap_button_map = "lrm";
      }
    ];
    wayland.windowManager.hyprland.settings.gesture = [
      "3, horizontal, workspace"
      "3, up, dispatcher, hyprexpo:expo, on"
      "3, down, dispatcher, hyprexpo:expo, off"
    ];
    wayland.windowManager.hyprland.settings.bindel = [
      ", XF86KbdBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl --device=smc::kbd_backlight set 10%+"
      ", XF86KbdBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl --device=smc::kbd_backlight set 10%-"
    ];
  };
  security.rtkit.enable = true;

  # Keep builds within the memory available on this 8 GB machine.
  nix.settings.max-jobs = 1;
  nix.settings.cores = 2;
}
