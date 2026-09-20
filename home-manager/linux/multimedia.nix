{
  pkgs,
}:
{
  installPackages = with pkgs; [
    # Media player
    vlc

    # Recording
    gpu-screen-recorder
    obs-studio

    # Screenshot
    grimblast
    satty

    # Audio
    pamixer
    pavucontrol
  ];
}
