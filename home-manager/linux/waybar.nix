{ ... }:
{
  programs.waybar = {
    enable = true;
    settings = [
      {
        height = 30;
        spacing = 4;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
          "mpris"
        ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "idle_inhibitor"
          "wireplumber"
          "network"
          "cpu"
          "memory"
          "temperature"
          "hyprland/language"
          "clock"
          "tray"
        ];

        "hyprland/window".max-length = 80;
        "hyprland/language".format = "{short}";
        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} {dynamic}";
          dynamic-len = 40;
          player-icons.default = "▶";
          status-icons.paused = "⏸";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };
        wireplumber = {
          format = "{volume}% {icon}";
          format-muted = "󰖁";
          format-icons = [
            ""
            ""
            ""
          ];
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
          on-scroll-up = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} 󰈀";
          format-disconnected = "Disconnected ⚠";
          tooltip-format = "{ifname} via {gwaddr}";
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        memory.format = "{}% ";
        temperature = {
          hwmon-path-abs = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
          input-filename = "temp1_input";
          critical-threshold = 80;
          format = "{temperatureC}°C ";
        };
        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        tray.spacing = 10;
      }
    ];
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };
  };
}
