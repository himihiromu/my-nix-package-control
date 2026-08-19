{ pkgs }:
let
  chatgpt = pkgs.callPackage ./chatgpt.nix { };
in
{
  installPackages = with pkgs; [
    # Terminal
    ghostty

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
    geary
    thunderbird

    # Photos
    gthumb

    # Image editing
    gimp
    krita

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
