{
  config,
  ...
}:
{
  programs.nushell = {
    enable = true;
    # Home Manager 26.11以降も従来の環境変数の読み込み方法を維持する。
    loadSessionVariables = false;
    # Home Managerの生成先
    configDir =
      "${config.xdg.configHome}/home-manager/nushell";
  };
}
