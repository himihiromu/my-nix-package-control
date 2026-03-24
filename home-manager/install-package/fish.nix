{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    plugins = [
      { name = "grc"; src = pkgs.fishPlugins.fzf-fish.src; }
    ];
  };

  # home-managerによるconfig.fishの生成を無効化し、手動管理のファイルを維持する
  xdg.configFile."fish/config.fish".enable = false;
}
