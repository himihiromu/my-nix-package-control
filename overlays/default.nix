{ inputs }:
final: prev: {
  bash-abbrev-alias = final.callPackage ../pkgs/bash-abbrev-alias { };
  keifu = final.callPackage ../pkgs/keifu { };
  filetree = final.callPackage ../pkgs/filetree { };
  chatgpt = final.callPackage ../pkgs/chatgpt { };
  orca-ide = final.callPackage ../pkgs/orca { };
  ghostty-wayland-ime = final.callPackage ../pkgs/ghostty-wayland-ime { };
  takt = final.callPackage ../pkgs/takt { inherit inputs; };
}
