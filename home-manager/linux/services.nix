# Hyprland GUI環境の常駐サービス設定
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Super+Space から呼ぶ Mozc / SKK 切り替えコマンドを用意する。
  toggleJapaneseInput = pkgs.callPackage ./toggle-japanese-input.nix { };
  wallpaperDirectory = "${config.home.homeDirectory}/Pictures/Wallpapers";
  defaultWallpaper = "${wallpaperDirectory}/hyprland-wall0.png";
  lua = lib.generators.mkLuaInline;
  bind = keys: action: {
    _args = [
      keys
      (lua action)
    ];
  };
  exec = keys: command: bind keys "hl.dsp.exec_cmd(${builtins.toJSON command})";
  repeatExec = keys: command: {
    _args = [
      keys
      (lua "hl.dsp.exec_cmd(${builtins.toJSON command})")
      {
        locked = true;
        repeating = true;
      }
    ];
  };
in
{
  imports = [
    ./waybar.nix
    ./obs
  ];

  home.file = {
    "Pictures/Wallpapers/hyprland-wall0.png".source = "${pkgs.hyprland}/share/hypr/wall0.png";
    "Pictures/Wallpapers/hyprland-wall1.png".source = "${pkgs.hyprland}/share/hypr/wall1.png";
    "Pictures/Wallpapers/hyprland-wall2.png".source = "${pkgs.hyprland}/share/hypr/wall2.png";
  };

  # Chezmoi owns Waypaper's static configuration.
  xdg.configFile."waypaper/config.ini".enable = false;

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = true;
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = defaultWallpaper;
          fit_mode = "cover";
        }
      ];
    };
  };

  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher server";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Environment = "USER_LAYER_SHELL=1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      };
      listener = [
        {
          timeout = 600; # 10 minutes
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1800; # 30 minutes
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      background = [ { color = "rgb(1e1e2e)"; } ];
      input-field = [
        {
          size = "300, 50";
          position = "0, -20";
          monitor = "";
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = false; # UWSM owns the graphical user session.
    settings = {
      monitor = [
        {
          output = "DP-2";
          mode = "preferred";
          position = "0x0";
          scale = 1;
        }
        {
          output = "HDMI-A-2";
          mode = "preferred";
          position = "1920x0";
          scale = 1;
        }
      ];
      config.input = {
        kb_layout = "jp";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };
      # Fcitx is started by UWSM's XDG autostart service.
      on._args = [
        "hyprland.start"
        (lua ''
          function() hl.exec_cmd("nm-applet --indicator") end
        '')
      ];
      env = [
        {
          _args = [
            "GTK_IM_MODULE"
            "fcitx"
          ];
        }
        {
          _args = [
            "QT_IM_MODULE"
            "fcitx"
          ];
        }
        {
          _args = [
            "XMODIFIERS"
            "@im=fcitx"
          ];
        }
        {
          _args = [
            "SDL_IM_MODULE"
            "fcitx"
          ];
        }
        {
          _args = [
            "GLFW_IM_MODULE"
            "ibus"
          ];
        }
        {
          _args = [
            "QT_QPA_PLATFORMTHEME"
            "qt6ct"
          ];
        }
      ];
      bind = [
        (exec "SUPER + Return" "uwsm app -- ghostty")
        (exec "SUPER + E" "uwsm app -- nemo")
        (exec "ALT + Space" "vicinae toggle")
        (exec "SUPER + Space" "${toggleJapaneseInput}/bin/toggle-japanese-input")
        (bind "SUPER + Q" "hl.dsp.window.close()")
        (bind "SUPER + W" "hl.dsp.window.close()")
        (bind "SUPER + F" ''hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" })'')
        (bind "SUPER + V" ''hl.dsp.window.float({ action = "toggle" })'')
        (exec "SUPER + L" "loginctl lock-session")
        (bind "SUPER + SHIFT + E" "hl.dsp.exit()")
        (exec "Print" "grimblast save area - | satty --filename - --copy-command wl-copy --early-exit --actions-on-escape exit")
        (exec "SHIFT + Print" "grimblast copy area")
        (exec "SUPER + SHIFT + C" "hyprpicker --autocopy")
      ]
      ++ lib.concatMap (i: [
        (bind "SUPER + ${toString i}" "hl.dsp.focus({ workspace = ${toString i} })")
        (bind "SUPER + SHIFT + ${toString i}" "hl.dsp.window.move({ workspace = ${toString i} })")
      ]) (lib.range 1 5)
      ++ [
        (repeatExec "XF86AudioRaiseVolume" "${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")
        (repeatExec "XF86AudioLowerVolume" "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
        (repeatExec "XF86MonBrightnessUp" "${pkgs.brightnessctl}/bin/brightnessctl --class=backlight --min-value=1 set 5%+")
        (repeatExec "XF86MonBrightnessDown" "${pkgs.brightnessctl}/bin/brightnessctl --class=backlight --min-value=1 set 5%-")
        # Mute must not repeat while the key is held.
        {
          _args = [
            "XF86AudioMute"
            (lua "hl.dsp.exec_cmd(${builtins.toJSON "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"})")
            { locked = true; }
          ];
        }
      ];
    };
  };
}
