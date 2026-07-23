{ ... }:
{
  programs.zsh = {
    enable = true;

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
