{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Hyprland
    hyprlock
    hypridle
    hyprpaper
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    hyprpicker
  ];
}
