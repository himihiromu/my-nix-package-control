{
  config,
  ...
}:
{
  programs.nushell = {
    enable = true;
    # Home Managerの生成先
    configDir =
      "${config.xdg.configHome}/home-manager/nushell";
  };
}
