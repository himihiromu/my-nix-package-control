{
  pkgs,
}:
{
  installPackages = with pkgs; [
    # Terminal
    ghostty

    # Launcher
    vicinae

    # Browser
    zen-browser
    chromium

    # Clipboard
    clipse

    # File Manager
    nemo

    # Wallpaper
    waypaper

    # Status Bar
    waybar

    # Notification
    swaynotificationcenter

    # Brightness
    brightnessctl
  ];
}
