{
  pkgs,
  inputs,
  system,
  ...
}:
{
  imports = inputs.nixpkgs.lib.optional (inputs.nixpkgs.lib.hasSuffix "-linux" system) ../linux;
  home.packages = [ pkgs.bruno ];
}
