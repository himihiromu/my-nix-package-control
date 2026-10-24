# nix eval --impure --json 'path:.#packages.x86_64-linux' \
#   --override-input local-options path:/path/to/options.nix \
#   --apply 'p: import ./tests/check-wsl.nix { configurations = p.nixosConfigurations; username = "nixos"; isDesktop = false; }'
{
  configurations,
  username,
  isDesktop,
}:
let
  wsl = configurations.nixos-wsl.config;
  home = wsl.home-manager.users.${username};
  names = builtins.map (p: p.pname or p.name or "") home.home.packages;
  physical =
    host:
    let
      c = configurations.${host}.config;
    in
    assert c.services.avahi.enable;
    assert c.programs.hyprland.enable == isDesktop;
    assert c.services.pipewire.enable == isDesktop;
    assert isDesktop -> c.security.polkit.enable;
    assert c.i18n.inputMethod.enable == isDesktop;
    assert c.networking.networkmanager.enable;
    c.system.build.toplevel.drvPath;
in
assert wsl.wsl.enable;
assert wsl.wsl.defaultUser == username;
assert wsl.home-manager.useGlobalPkgs;
assert wsl.home-manager.useUserPackages;
assert builtins.elem username wsl.nix.settings.trusted-users;
assert wsl.nix.gc.automatic;
assert wsl.nix.optimise.automatic;
assert wsl.virtualisation.docker.enable;
assert wsl.virtualisation.docker.rootless.enable;
assert wsl.services.openssh.enable;
assert !wsl.services.avahi.enable;
assert !wsl.programs.hyprland.enable;
assert !wsl.services.greetd.enable;
assert !wsl.services.pipewire.enable;
assert !wsl.security.polkit.enable;
assert !wsl.i18n.inputMethod.enable;
assert wsl.time.timeZone != "Asia/Tokyo";
assert !wsl.networking.networkmanager.enable;
assert !wsl.services.fwupd.enable;
assert !wsl.services.blueman.enable;
assert !wsl.services.ratbagd.enable;
assert !home.wayland.windowManager.hyprland.enable;
assert home.programs.zed-editor.enable == isDesktop;
assert
  isDesktop
  || home.home.file
  ? ".zed_server/${configurations.nixos-wsl.pkgs.zed-editor.remoteServerExecutableName}";
assert builtins.elem "git" names;
assert builtins.elem "codex" names;
assert builtins.elem "bruno" names == isDesktop;
assert builtins.elem "chatgpt" names == isDesktop;
{
  wsl = wsl.system.build.toplevel.drvPath;
  nixos = physical "nixos";
  macbook-air = physical "macbook-air";
}
