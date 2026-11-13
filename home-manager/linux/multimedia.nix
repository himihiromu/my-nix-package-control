{
  pkgs,
}:
{
  installPackages = with pkgs; [
    # Media player
    vlc

    # Recording
    gpu-screen-recorder

    # Screenshot
    grimblast
    satty

    # Audio
    pamixer
    pavucontrol
  ];
}
