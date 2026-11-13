{
  config,
  lib,
  pkgs,
  ...
}:
let
  obsControl = pkgs.callPackage ./control.nix { };
  commands = [
    {
      key = "O";
      command = "uwsm app -- obs";
    }
    {
      key = "F9";
      command = "${obsControl}/bin/obs-control start";
    }
    {
      key = "F10";
      command = "${obsControl}/bin/obs-control stop";
    }
    {
      key = "F11";
      command = "${obsControl}/bin/obs-control replay";
    }
  ];
in
{
  # OBS owns its writable settings; chezmoi imports the selected GUI-generated files.
  programs.obs-studio = {
    enable = true;
    plugins = [ pkgs.obs-studio-plugins.obs-pipewire-audio-capture ];
  };
  home.packages = [ obsControl ];
  # Keep OBS usable with the existing Hyprlang config and the separate Lua migration.
  wayland.windowManager.hyprland.settings.bind =
    if config.wayland.windowManager.hyprland.configType == "lua" then
      map (entry: {
        _args = [
          "SUPER + SHIFT + ${entry.key}"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${builtins.toJSON entry.command})")
        ];
      }) commands
    else
      map (entry: "SUPER SHIFT, ${entry.key}, exec, ${entry.command}") commands;
}
