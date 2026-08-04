{ 
  config,
  lib,
  ... 
}:
let
  generatedZshDir = "${config.xdg.configHome}/home-manager/zsh";
  userZshrc = "${config.home.homeDirectory}/.zshrc";
in
{
  programs.zsh = {
    enable = true;

    # Home Managerの生成先
    dotDir = generatedZshDir;

    # 既存の、chezmoi等で管理している.zshrcを読み込む
    initContent = lib.mkOrder 500 ''
      if [[ -f "${userZshrc}" ]]; then
        source "${userZshrc}"
      fi
    '';
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
