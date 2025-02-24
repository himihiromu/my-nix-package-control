{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    vim-src = {
      url = "github:vim/vim";
      flake = false;
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixos-wsl, neovim-nightly-overlay, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem (
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system}.extend (neovim-nightly-overlay.overlays.default);
    in
    {
      formatter = pkgs.nixfmt-rfc-style;
      packages.my-packages = pkgs.buildEnv {
        name = "my-packages-list";
        paths = with pkgs; [
          git
          curl
          nixfmt-rfc-style
          neovim
        ];
      };
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            nixos-wsl.nixosModules.default
            {
              system.stateVersion = "24.05";
              wsl.enable = true;
            }
          ];
        };
      };
      apps.update = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "update-script" ''
            set -e
            echo "Updating flake..."
            nix --extra-experimental-features nix-command --extra-experimental-features flakes flake update
            echo "Updating profile..."
            nix --extra-experimental-features nix-command --extra-experimental-features flakes profile upgrade my-packages
            echo "Update complete!"
          ''
        );
      };
      apps.install = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "update-script" ''
            set -e
            echo "Updating flake..."
            nix --extra-experimental-features nix-command --extra-experimental-features flakes flake update
            echo "Updating profile..."
            nix --extra-experimental-features nix-command --extra-experimental-features flakes profile install my-packages
            echo "Update complete!"
          ''
        );
      };
    }
  );
}

