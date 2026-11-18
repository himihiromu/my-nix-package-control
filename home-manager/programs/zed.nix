{
  pkgs,
  lib,
  guiApps,
  ...
}:
{
  programs.zed-editor = {
    enable = guiApps;
    installRemoteServer = false;
  };

  # CLI環境ではGUI本体を入れず、従来のリモート接続先として使えるようにする。
  home.file = lib.optionalAttrs (!guiApps && pkgs.zed-editor ? remote_server) {
    ".zed_server/${pkgs.zed-editor.remoteServerExecutableName}".source =
      lib.getExe' pkgs.zed-editor.remote_server pkgs.zed-editor.remoteServerExecutableName;
  };
}
