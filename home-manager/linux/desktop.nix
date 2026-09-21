{ pkgs }:
let
  # Use Wayland's native IME path in Ghostty. Forcing the Fcitx GTK module
  # breaks Japanese input in Codex CLI on this setup.
  ghosttyWayland = pkgs.symlinkJoin {
    name = "ghostty-wayland-ime-${pkgs.ghostty.version}";
    paths = [ pkgs.ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/ghostty" --unset GTK_IM_MODULE

      # Pin launcher actions to this wrapper as well as D-Bus activation.
      # A bare `ghostty` can resolve to another installation through PATH.
      desktop=share/applications/com.mitchellh.ghostty.desktop
      substitute "$out/$desktop" "$out/$desktop.tmp" \
        --replace-fail "Exec=ghostty" "Exec=$out/bin/ghostty"
      mv "$out/$desktop.tmp" "$out/$desktop"

      # D-Bus and systemd activation must also use the wrapped executable.
      for service in \
        share/dbus-1/services/com.mitchellh.ghostty.service \
        lib/systemd/user/app-com.mitchellh.ghostty.service; do
        if [ -f "$out/$service" ]; then
          substitute "$out/$service" "$out/$service.tmp" \
            --replace-fail "${pkgs.ghostty}/bin/ghostty" "$out/bin/ghostty"
          mv "$out/$service.tmp" "$out/$service"
        fi
      done
    '';
    meta = pkgs.ghostty.meta;
  };
in
{
  installPackages = with pkgs; [
    # Terminal
    ghosttyWayland

    # Launcher
    vicinae

    # Browser
    chromium
    firefox
    floorp-bin
    google-chrome

    # Mail
    thunderbird

    # Chat
    discord

    # Video conferencing
    zoom-us

    # Photos
    gthumb

    # Image editing
    gimp
    krita

    # Editor
    vscode

    # Game launcher
    heroic

    # Clipboard
    clipse
    wl-clipboard

    # File Manager
    nemo

    # File sharing
    localsend

    # System monitor
    mission-center

    # Wallpaper
    waypaper

    # Notification
    swaynotificationcenter

    # Brightness
    brightnessctl

    # Mouse configuration
    piper

    # Desktop integration
    networkmanagerapplet
    qt6Packages.qt6ct
  ];
}
