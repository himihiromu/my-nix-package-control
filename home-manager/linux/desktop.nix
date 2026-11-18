{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Terminal
    ghostty-wayland-ime

    # Launcher
    vicinae

    # Browser
    chromium
    firefox
    floorp-bin
    google-chrome

    # AI assistant
    chatgpt

    # Mail
    thunderbird

    # Chat
    discord

    # Video conferencing
    zoom-us

    # Photos
    gthumb

    # Image editing
    gimp
    krita

    # Editor
    vscode
    orca-ide

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
