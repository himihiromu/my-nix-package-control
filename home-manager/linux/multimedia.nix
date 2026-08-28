{
  pkgs,
}:
{
  installPackages = with pkgs; [
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
