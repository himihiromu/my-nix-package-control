{
  lib,
  writeShellApplication,
  xdg-utils,
  makeDesktopItem,
  symlinkJoin,
}:
let
  launcher = writeShellApplication {
    name = "muse-web";
    text = ''
      exec ${xdg-utils}/bin/xdg-open 'https://muse.ai/'
    '';
    meta = {
      description = "Open Meta Muse in the default browser";
      homepage = "https://muse.ai/";
      platforms = lib.platforms.linux;
      mainProgram = "muse-web";
    };
  };
  desktop = makeDesktopItem {
    name = "muse-web";
    desktopName = "Muse (Web)";
    comment = "Meta Muse personal AI agent";
    exec = "${launcher}/bin/muse-web";
    icon = "web-browser";
    categories = [ "Network" ];
    terminal = false;
  };
in
symlinkJoin {
  name = "muse-web";
  paths = [
    launcher
    desktop
  ];
  meta = launcher.meta;
}
