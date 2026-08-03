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
    chromium

    # Clipboard
    clipse
    wl-clipboard

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

    # Desktop integration
    networkmanagerapplet
    qt6Packages.qt6ct
  ];
}
