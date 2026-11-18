{ pkgs, inputs, ... }: {
  imports = [
    inputs.prismix.homeModules.default
    ../install-package/minecraft
  ];
  home.packages = [ pkgs.heroic ];
}
