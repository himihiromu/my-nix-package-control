{
  pkgs,
  username,
  system,
  isDesktop,
  isWsl ? false,
  inputs,
  ...
}:
let
  isMac = builtins.elem system [
    "x86_64-darwin"
    "aarch64-darwin"
  ];
  isLinux = builtins.elem system [
    "x86_64-linux"
    "aarch64-linux"
  ];
in
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./programs/neovim.nix
    ./shell
    ./programs/takt.nix
    ./programs/zed.nix
    ./packages/common.nix
  ]
  ++ inputs.nixpkgs.lib.optionals isMac [ ./packages/darwin.nix ]
  ++ inputs.nixpkgs.lib.optionals (isLinux && isDesktop) [
    ./linux
    inputs.prismix.homeModules.default
    ./install-package/minecraft
  ]
  ++ (
    if isLinux && isDesktop && !isWsl then
      [
        ./linux/services.nix
        ./linux/user-dirs.nix
      ]
    else
      [ ]
  );

  home = {
    username = username;
    homeDirectory = if isMac then "/Users/${username}" else "/home/${username}";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.05";

  };

  programs.home-manager.enable = true;
}
