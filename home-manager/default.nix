{
  pkgs,
  username,
  system,
  isDesktop,
  nixvim,
  ...
}:
let
  commonPackage = (import ./install-package/common.nix {inherit pkgs;}).installPackages;
  isMac =
    if (builtins.toString system) == "x86_64-darwin" then true
    else if (builtins.toString system) == "aarch64-darwin" then true
    else false;
  machinePackage =
    if isMac then (import ./install-package/darwin.nix {inherit pkgs;}).installPackages
    else [];
  zed = import ./install-package/zed.nix { inherit pkgs; inherit isDesktop; };
  nix-vim-package = import ./install-package/neovim.nix { inherit pkgs; };
  fish-package = import ./install-package/fish.nix { inherit pkgs; };
in
{
  imports = [
    zed
    nixvim.homeManagerModules.nixvim
    nix-vim-package
    fish-package
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    file = if isMac then {
      ".lima/_config/default.yaml".source = ../config/lima/default.yaml;
    }
    else {};

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.05";

    packages = commonPackage ++ machinePackage;
  };

  programs.home-manager.enable = true;
}
