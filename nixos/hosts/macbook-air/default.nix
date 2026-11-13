{
  pkgs,
  username,
  lib,
  ...
}:
let
  lua = lib.generators.mkLuaInline;
  bind = keys: action: {
    _args = [
      keys
      (lua action)
    ];
  };
  exec = keys: command: bind keys "hl.dsp.exec_cmd(${builtins.toJSON command})";
in
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
      (exec "code:130" "${pkgs.fcitx5}/bin/fcitx5-remote -o")
      (exec "code:131" "${pkgs.fcitx5}/bin/fcitx5-remote -c")
      (exec "Hiragana_Katakana" "${pkgs.fcitx5}/bin/fcitx5-remote -o")
      (exec "Eisu_toggle" "${pkgs.fcitx5}/bin/fcitx5-remote -c")
      # Scrolling layout: move focus between columns and change their order.
      (bind "SUPER + H" ''hl.dsp.layout("focus l")'')
      (bind "SUPER + ALT + L" ''hl.dsp.layout("focus r")'')
      (bind "SUPER + SHIFT + H" ''hl.dsp.layout("swapcol l")'')
      (bind "SUPER + SHIFT + L" ''hl.dsp.layout("swapcol r")'')
      (bind "SUPER + Comma" ''hl.dsp.layout("colresize -conf")'')
      (bind "SUPER + Period" ''hl.dsp.layout("colresize +conf")'')
      (bind "SUPER + P" ''hl.dsp.layout("promote")'')
      (bind "SUPER + SHIFT + P" ''hl.dsp.layout("expel")'')
      (bind "SUPER + CTRL + P" ''hl.dsp.layout("consume_or_expel prev")'')
      (bind "SUPER + I" ''hl.dsp.layout("fit active")'')

      {
        _args = [
          "XF86KbdBrightnessUp"
          (lua "hl.dsp.exec_cmd(${builtins.toJSON "${pkgs.brightnessctl}/bin/brightnessctl --device=smc::kbd_backlight set 10%+"})")
          {
            locked = true;
            repeating = true;
          }
        ];
      }
      {
        _args = [
          "XF86KbdBrightnessDown"
          (lua "hl.dsp.exec_cmd(${builtins.toJSON "${pkgs.brightnessctl}/bin/brightnessctl --device=smc::kbd_backlight set 10%-"})")
          {
            locked = true;
            repeating = true;
          }
        ];
      }
    ];
    wayland.windowManager.hyprland.settings.config.general = {
      layout = "scrolling";
    };
    wayland.windowManager.hyprland.settings.config.scrolling = {
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
        tap_to_click = true;
        tap_button_map = "lrm";
      }
    ];
    wayland.windowManager.hyprland.settings.gesture = [
      {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      }
      {
        fingers = 3;
        direction = "up";
        action = lua ''function() hl.plugin.hyprexpo.expo("on") end'';
      }
      {
        fingers = 3;
        direction = "down";
        action = lua ''function() hl.plugin.hyprexpo.expo("off") end'';
      }
    ];
  };
  security.rtkit.enable = true;

  # Keep builds within the memory available on this 8 GB machine.
  nix.settings.max-jobs = 1;
  nix.settings.cores = 2;
}
