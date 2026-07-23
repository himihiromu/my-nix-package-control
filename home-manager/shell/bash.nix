{ ... }:
{
  programs.bash = {
    enable = true;
  };

  # home-managerによる.bashrcの生成を無効化し、手動管理のファイルを維持する
  home.file.".bashrc".enable = false;
  home.file.".profile".enable = false;
}
