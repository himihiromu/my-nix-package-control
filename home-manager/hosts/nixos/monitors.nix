# AMD desktop outputs. Laptop/standalone configurations choose their own layout.
{ config, lib, ... }:
{
  wayland.windowManager.hyprland.settings.monitor =
    lib.mkIf config.wayland.windowManager.hyprland.enable
      [
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
}
