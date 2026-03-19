{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    plugins =  [
      { name = "grc"; src = pkgs.fishPlugins.fzf-fish.src; }
    ];
  };
}
