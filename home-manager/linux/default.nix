{
  pkgs,
}:
let
  desktop = (import ./desktop.nix { inherit pkgs; }).installPackages;
  multimedia = (import ./multimedia.nix { inherit pkgs; }).installPackages;
in
{
  installPackages = desktop ++ multimedia;
}
