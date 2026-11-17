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
  commonPackage = (import ./install-package/common.nix { inherit pkgs isDesktop; }).installPackages;
  isMac =
    if (builtins.toString system) == "x86_64-darwin" then
      true
    else if (builtins.toString system) == "aarch64-darwin" then
      true
    else
      false;
  isLinux =
    if (builtins.toString system) == "x86_64-linux" then
      true
    else if (builtins.toString system) == "aarch64-linux" then
      true
    else
      false;
  machinePackage =
    if isMac then
      (import ./install-package/darwin.nix { inherit pkgs; }).installPackages
    else if isLinux && isDesktop then
      (import ./linux { inherit pkgs; }).installPackages
    else
      [ ];
  zed = ./install-package/zed.nix;
  nix-vim-package = ./install-package/neovim.nix;
  shell = ./shell;
  takt-package = ./install-package/takt.nix;
in
{
  imports =
    [
      inputs.nixvim.homeModules.nixvim
      nix-vim-package
      shell
      takt-package
      zed
    ]
    ++ inputs.nixpkgs.lib.optionals (isLinux && isDesktop) [
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

    packages = commonPackage ++ machinePackage;
  };

  programs.home-manager.enable = true;
}
