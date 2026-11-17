{ pkgs, inputs, ... }: {
  imports = [
    inputs.minecraft.homeModules.default
  ];
  home.packages = [ pkgs.heroic ];
}
