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
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-wsl, neovim-nightly-overlay, flake-utils, home-manager, nix-darwin, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (
    system:
    let
      inherit (import ./user-options/options.nix) username;
      pkgs = nixpkgs.legacyPackages.${system}.extend (neovim-nightly-overlay.overlays.default);
    in
    {
      formatter = pkgs.nixfmt-rfc-style;
      packages = {
        my-package = pkgs.buildEnv {
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
        homeConfigurations = {
          myHomeConfig = home-manager.lib.homeManagerConfiguration {
            pkgs = pkgs;
            extraSpecialArgs = {inherit inputs;};
            modules = [./home-manager/default.nix];
          };
        };
        darwinConfigurations = {
          mac-config = nix-darwin.lib.darwinSystem {
            system = system;
            modules = [ 
              # ./configuration.nix
              (import ./nix-darwin/default.nix { inherit pkgs;})
            ];
          };
        };
      };
      #   inherit system;
      #   modules = [ home-manager.darwinModules.home-manager ./nix-darwin/default.nix ];
      # };
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
      legacyPackages = {
        inherit (pkgs) home-manager;
        homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home/home.nix
          ];
        };
      };
    }
  );
}

