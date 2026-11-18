{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    lima
    skhd
    docker-credential-helpers
  ];
}
