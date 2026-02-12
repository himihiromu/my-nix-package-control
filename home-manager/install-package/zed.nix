{
  pkgs,
  isDesktop,
  ...
}:
let
  inherit (pkgs.zed-editor) version;
in
{
  programs.zed-editor = {
    enable = true;
    installRemoteServer = if isDesktop then false else true;
  };
  # home.file.".zed_server/zed-remote-server-dev-build".source = config.lib.file.mkOutOfStoreSymlink ".zed_server/zed-remote-server-stable-${version}";
}