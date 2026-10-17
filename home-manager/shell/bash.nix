{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
  };

  # dotfiles の .bashrc が対話 Emacs モードで読み込むライブラリ。
  # パッケージは install-package/common.nix でインストールする。
  xdg.configFile."bash/abbrev-alias.plugin.bash".source =
    "${pkgs.bash-abbrev-alias}/share/bash-abbrev-alias/abbrev-alias.plugin.bash";

  # home-managerによる.bashrcの生成を無効化し、手動管理のファイルを維持する
  home.file.".bashrc".enable = false;
  home.file.".profile".enable = false;

  # macOSではchezmoiが.bash_profileを管理するため、Home Managerの管理から除外する
  home.file.".bash_profile".enable = !pkgs.stdenv.isDarwin;
}
