{
  pkgs,
}:
let
  # Waypaper 2.7 still calls the preload/unload IPC requests removed in
  # hyprpaper 0.8. Wallpapers are loaded directly by the wallpaper request now.
  waypaperForHyprpaper08 = pkgs.waypaper.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace waypaper/changer.py \
        --replace-fail '                subprocess.check_output(unload_command, encoding="utf-8").strip()' '                # hyprpaper >= 0.8 loads wallpapers directly' \
        --replace-fail '                subprocess.check_output(preload_command, encoding="utf-8").strip()' '                # preload was removed in hyprpaper 0.8' \
        --replace-fail '                result = subprocess.check_output(wallpaper_command, encoding="utf-8").strip()' $'                subprocess.check_output(wallpaper_command, encoding="utf-8")\n                result = "ok"'
    '';
  });
in
{
  installPackages = with pkgs; [
    # Terminal
    ghostty

    # Launcher
    vicinae

    # Browser
    chromium

    # Clipboard
    clipse
    wl-clipboard

    # File Manager
    nemo

    # Wallpaper
    waypaperForHyprpaper08

    # Notification
    swaynotificationcenter

    # Brightness
    brightnessctl

    # Mouse configuration
    piper

    # Desktop integration
    networkmanagerapplet
    qt6Packages.qt6ct
  ];
}
