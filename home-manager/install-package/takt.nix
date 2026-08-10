{ pkgs, inputs, ... }:

{
  home.packages = [
    # Takt 本体。nixpkgs ではなく flake input から取得する
    inputs.takt.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
