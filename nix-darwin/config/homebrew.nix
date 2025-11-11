{ pkgs }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    caskArgs = {
      appdir = "~/Applications";
    };
    taps = [
      "gcenx/wine"
      "oven-sh/bun"
      "nikitabobko/tap"
    ];
    casks = [
      "cursor"
      "raycast"
      "amazon-q"
      "jetbrains-toolbox"
      "aquaskk"
      # "microsoft-auto-update"
      "chrome-remote-desktop-host"
      # "microsoft-office"
      # "docker"
      "stoplight-studio"
      "firefox"
      "visual-studio-code"
      "floorp"
      "vivaldi"
      "geektool"
      "warp"
      "gimp"
      "wave"
      "google-chrome"
      "zed"
      "google-japanese-ime"
      "zoom"
    ];
    masApps = {
      RunCat = 1429033973;
    };
  };
}

