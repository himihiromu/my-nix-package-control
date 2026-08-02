{ config, pkgs, ... }:

{
  # Hyprland
  programs.hyprland = {
    enable = true;
    withXWAYLAND = true;
  };

  # Greetd + Tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # XDG Portal
  xdg.portal.enable = true;

  # PolicyKit
  security.polkit.enable = true;

  # Locale
  i18n = {
    defaultLocale = "ja_JP.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };
    supportedLocales = [
      "ja_JP.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  # Timezone
  time.timeZone = "Asia/Tokyo";

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # Fcitx5 + Mozc + SKK
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs.fcitx5-with-addons; [
      fcitx5-skk
      fcitx5-mozc
    ];
  };

  # XDG User Directories
  xdg.userDirs = {
    enable = true;
    createGomeDirectories = true;
  };
}
