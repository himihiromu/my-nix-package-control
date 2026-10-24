{
  pkgs,
  lib,
  isDesktop,
  ...
}:
{
  programs.zed-editor = {
    enable = isDesktop;
    installRemoteServer = false;
  };

  # CLI環境ではGUI本体を入れず、従来のリモート接続先として使えるようにする。
  home.file = lib.optionalAttrs (!isDesktop && pkgs.zed-editor ? remote_server) {
    ".zed_server/${pkgs.zed-editor.remoteServerExecutableName}".source =
      lib.getExe' pkgs.zed-editor.remote_server pkgs.zed-editor.remoteServerExecutableName;
  };
}
