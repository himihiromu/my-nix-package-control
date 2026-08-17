{
  config,
  pkgs,
  ...
}:
let
  notificationCount = pkgs.writeShellApplication {
    name = "waybar-notification-count";
    runtimeInputs = [ pkgs.swaynotificationcenter ];
    text = ''
      count="$(swaync-client --skip-wait --count 2>/dev/null || true)"

      if [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
        printf '%s\n' "$count"
      fi
    '';
  };

  dockerContainerCount = pkgs.writeShellApplication {
    name = "waybar-docker-container-count";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.docker-client
    ];
    text = ''
      containers="$(docker ps --quiet 2>/dev/null)" || exit 0

      if [ -n "$containers" ]; then
        printf '%s\n' "$containers" | wc --lines
      fi
    '';
  };

  nixUpdateCount = pkgs.writeShellApplication {
    name = "waybar-nix-update-count";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.nix
    ];
    text = ''
      flake_directory="${config.home.homeDirectory}/ghq/github.com/himihiromu/my-nix-package-control"

      if [ ! -f "$flake_directory/flake.lock" ]; then
        exit 0
      fi

      temporary_directory="$(mktemp --directory)"
      trap 'rm -r -- "$temporary_directory"' EXIT
      updated_lock="$temporary_directory/flake.lock"

      if ! nix flake update \
        --flake "$flake_directory" \
        --output-lock-file "$updated_lock" \
        >/dev/null 2>&1; then
        exit 0
      fi

      count="$(
        jq --null-input \
          --slurpfile current "$flake_directory/flake.lock" \
          --slurpfile updated "$updated_lock" \
          '
            $current[0].nodes as $currentNodes
            | $updated[0].nodes as $updatedNodes
            | [
                $updatedNodes
                | keys[] as $key
                | select(
                    $key != "root"
                    and $updatedNodes[$key].locked != $currentNodes[$key].locked
                  )
              ]
            | length
          '
      )"

      if (( count > 0 )); then
        printf '%s\n' "$count"
      fi
    '';
  };
in
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
          "custom/nix-updates"
          "custom/docker-containers"
          "custom/notifications"
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
        "custom/nix-updates" = {
          exec = "${nixUpdateCount}/bin/waybar-nix-update-count";
          interval = 21600;
          format = " {}";
          tooltip-format = "更新可能なflake入力: {}";
          hide-empty-text = true;
        };
        "custom/docker-containers" = {
          exec = "${dockerContainerCount}/bin/waybar-docker-container-count";
          interval = 10;
          format = " {}";
          tooltip-format = "実行中のDockerコンテナ: {}";
          hide-empty-text = true;
        };
        "custom/notifications" = {
          exec = "${notificationCount}/bin/waybar-notification-count";
          interval = 5;
          format = " {}";
          tooltip-format = "通知: {}";
          hide-empty-text = true;
          on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client --toggle-panel";
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
