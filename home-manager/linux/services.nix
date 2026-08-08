# Hyprland GUI環境の常駐サービス設定
{
  config,
  lib,
  pkgs,
  ...
}:
let
  wallpaperDirectory = "${config.home.homeDirectory}/Pictures/Wallpapers";
  defaultWallpaper = "${wallpaperDirectory}/hyprland-wall0.png";
  waypaperConfig = pkgs.writeText "waypaper-config.ini" ''
    [Settings]
    folder = ${wallpaperDirectory}
    backend = hyprpaper
    fill = fill
    sort = name
    monitors = All
    wallpaper = ${defaultWallpaper}
    use_xdg_state = True
  '';
  waypaperInitialState = pkgs.writeText "waypaper-state.ini" ''
    [State]
    folder = ${wallpaperDirectory}
    monitors = All
    wallpaper = ${defaultWallpaper}
  '';
in
{
  imports = [ ./waybar.nix ];

  home.file = {
    "Pictures/Wallpapers/hyprland-wall0.png".source = "${pkgs.hyprland}/share/hypr/wall0.png";
    "Pictures/Wallpapers/hyprland-wall1.png".source = "${pkgs.hyprland}/share/hypr/wall1.png";
    "Pictures/Wallpapers/hyprland-wall2.png".source = "${pkgs.hyprland}/share/hypr/wall2.png";
  };

  # Keep Waypaper's chosen wallpaper in its mutable state file while managing
  # the backend and wallpaper directory declaratively.
  home.activation.waypaperConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/waypaper"
    run install -m 0644 ${waypaperConfig} "$HOME/.config/waypaper/config.ini"
    run mkdir -p "$HOME/.local/state/waypaper"
    if [[ -e "$HOME/.local/state/waypaper/state.ini" ]]; then
      run ${pkgs.gnused}/bin/sed -i \
        's|^folder = .*|folder = ${wallpaperDirectory}|' \
        "$HOME/.local/state/waypaper/state.ini"
    else
      run install -m 0644 ${waypaperInitialState} "$HOME/.local/state/waypaper/state.ini"
    fi
  '';

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
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
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
    systemd.enable = false; # UWSM owns the graphical user session.
    settings = {
      monitor = [
        "DP-2,preferred,0x0,1"
        "HDMI-A-2,preferred,1920x0,1"
      ];
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$fileManager" = "nemo";
      exec-once = [
        "fcitx5 -d --replace"
        "swaync"
        "nm-applet --indicator"
      ];
      env = [
        "GTK_IM_MODULE,fcitx"
        "QT_IM_MODULE,fcitx"
        "XMODIFIERS,@im=fcitx"
        "SDL_IM_MODULE,fcitx"
        "GLFW_IM_MODULE,ibus"
        "QT_QPA_PLATFORMTHEME,qt6ct"
      ];
      input = {
        kb_layout = "jp";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };
      bind = [
        "$mod, Return, exec, uwsm app -- $terminal"
        "$mod, E, exec, uwsm app -- $fileManager"
        "$mod, Space, exec, vicinae toggle"
        "$mod, Q, killactive"
        "$mod, W, killactive"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, L, exec, loginctl lock-session"
        "$mod SHIFT, E, exit"
        ", Print, exec, grimblast save area - | satty --filename - --copy-command wl-copy --early-exit --actions-on-escape exit"
        "SHIFT, Print, exec, grimblast copy area"
        "$mod SHIFT, C, exec, hyprpicker --autocopy"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
      ];
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
    };
  };
}
