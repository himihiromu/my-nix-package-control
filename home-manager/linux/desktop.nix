{ pkgs }:
{
  installPackages = with pkgs; [
    # Terminal
    ghostty

    # Launcher
    vicinae

    # Browser
    chromium

    # Editor
    vscode

    # Game launcher
    heroic

    # Clipboard
    clipse
    wl-clipboard

    # File Manager
    nemo

    # File sharing
    localsend

    # System monitor
    mission-center

    # Wallpaper
    waypaper

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
