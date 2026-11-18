{
  ghostty,
  symlinkJoin,
  makeWrapper,
}:
symlinkJoin {
  name = "ghostty-wayland-ime-${ghostty.version}";
  paths = [ ghostty ];
  nativeBuildInputs = [ makeWrapper ];
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
          --replace-fail "${ghostty}/bin/ghostty" "$out/bin/ghostty"
        mv "$out/$service.tmp" "$out/$service"
      fi
    done
  '';
  meta = ghostty.meta;
}
