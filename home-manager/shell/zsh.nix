{ 
  config,
  lib,
  ... 
}:
let
  generatedZshDir = "${config.xdg.configHome}/home-manager/zsh";
in
{
  programs.zsh = {
    enable = true;

    # Home Managerの生成先
    dotDir = generatedZshDir;

    zsh-abbr = {
      enable = true;
      abbreviations = {
        la = "ls -a";
        ll = "ls -l";
        lal = "ls -al";
      };
    };
  };
}
