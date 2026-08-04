# Hyprland GUI環境の常駐サービス設定
# services.*.enable のみ管理する
# 必要になったタイミングで追加する
{ pkgs, ... }:
{
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
      monitor = ",preferred,auto,1";
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$fileManager" = "nemo";
      exec-once = [
        "fcitx5 -d --replace"
        "waybar"
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
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, L, exec, loginctl lock-session"
        "$mod SHIFT, E, exit"
        ", Print, exec, grimblast copy area"
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
