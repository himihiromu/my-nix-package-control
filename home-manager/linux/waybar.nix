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
          "bluetooth"
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
        bluetooth = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          on-click = "blueman-manager";
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
