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
    hyprpaper
    waypaper

    # Lock
    hyprlock

    # Idle
    hypridle

    # Notification
    swaynotificationcenter

    # Status Bar
    waybar

    # PolicyKit
    hyprpolkitagent

    # Portal
    xdg-desktop-portal-hyprland

    # Brightness
    brightnessctl

    # Color Picker
    hyprpicker

    # Audio
    pamixer
    pavucontrol

    # Screenshot
    grimblast
    satty
  ];
}
