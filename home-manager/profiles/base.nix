{ inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../programs/neovim.nix
    ../programs/takt.nix
    ../programs/zed.nix
    ../shell
    ../packages/common.nix
  ];
}
