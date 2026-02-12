{ pkgs, isDesktop }:
let
  installPackages = (import ./cask.nix).installPackages;
in
{
  homebrew = {
    enable = isDesktop;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    caskArgs = {
      appdir = "~/Applications";
    };
    casks = (if isDesktop then installPackages else []);
    masApps = {
      RunCat = 1429033973;
    };
  };
}

