{
  description = "Minecraft environments and non-destructive PrismLauncher activation";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    prismix = {
      url = "git+https://codeberg.org/OliMoli/prismix?ref=refs/tags/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ self, nixpkgs, ... }:
    {
      homeModules.default = { ... }: {
        imports = [
          inputs.prismix.homeModules.default
          ./modules
        ];
      };
      checks.x86_64-linux.metadata =
        let
          fixture = import ./tests/fixture.nix { flake = self; };
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        builtins.deepSeq fixture.metadata (pkgs.runCommand "minecraft-metadata-check" { } "touch $out");
    };
}
