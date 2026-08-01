{
  pkgs,
}:
{
  installPackages = with pkgs; [
    # Recording
    gpu-screen-recorder
    obs-studio
  ];
}
