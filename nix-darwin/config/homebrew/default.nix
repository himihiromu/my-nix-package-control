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
    };
    caskArgs = {
      appdir = "~/Applications";
    };
    # Orca は Homebrew 本体ではなくサードパーティ tap で配布されている
    taps = [
      "stablyai/orca"
    ];
    casks = (if isDesktop then installPackages else []);
    masApps = {
      RunCat = 6757801838;
    };
  };
}

