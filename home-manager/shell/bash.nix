{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
  };

  # home-managerによる.bashrcの生成を無効化し、手動管理のファイルを維持する
  home.file.".bashrc".enable = false;
  home.file.".profile".enable = false;

  # macOSではchezmoiが.bash_profileを管理するため、Home Managerの管理から除外する
  home.file.".bash_profile".enable = !pkgs.stdenv.isDarwin;
}
