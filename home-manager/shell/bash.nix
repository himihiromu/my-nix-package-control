{ pkgs, ... }:
let
  bashAbbrevAlias = pkgs.fetchFromGitHub {
    owner = "momo-lab";
    repo = "bash-abbrev-alias";
    rev = "6afb671fc95b3c559f2665637df65d9060f4d320";
    hash = "sha256-bvbMyniy5TGoU0hVGKV2bo+qf6fAfMjlJQ1/DYw5RKo=";
  };
in
{
  programs.bash = {
    enable = true;
  };

  # dotfiles の .bashrc が対話 Emacs モードで読み込むライブラリ。
  # ソースは固定し、シェル起動時のネットワークアクセスを避ける。
  xdg.configFile."bash/abbrev-alias.plugin.bash".source =
    "${bashAbbrevAlias}/abbrev-alias.plugin.bash";

  # home-managerによる.bashrcの生成を無効化し、手動管理のファイルを維持する
  home.file.".bashrc".enable = false;
  home.file.".profile".enable = false;

  # macOSではchezmoiが.bash_profileを管理するため、Home Managerの管理から除外する
  home.file.".bash_profile".enable = !pkgs.stdenv.isDarwin;
}
