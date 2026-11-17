{
  username,
  system,
  isDesktop,
  isWsl ? false,
  homeProfiles ? null,
  inputs,
  ...
}:
let
  selected = import ./profiles/select.nix {
    inherit (inputs.nixpkgs) lib;
    inherit system isDesktop isWsl;
    requested = homeProfiles;
  };
in
{
  imports = map (name: ./profiles + "/${name}.nix") selected;
  _module.args.guiApps = builtins.elem "gui-apps" selected;
  home = {
    inherit username;
    homeDirectory =
      if inputs.nixpkgs.lib.hasSuffix "-darwin" system then "/Users/${username}" else "/home/${username}";
    stateVersion = "24.05";
  };
  programs.home-manager.enable = true;
}
