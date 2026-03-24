{
  pkgs
}:
{
  installPackages = with pkgs; [
    lima
    skhd
    docker-credential-helpers
    zsh-abbr
  ];
}
