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
  
    zed = {
      url = "github:zed-industries/zed";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-wsl, neovim-nightly-overlay, flake-utils, home-manager, nix-darwin, zed, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (
    system:
    let
      inherit (import ./user-options/options.nix) username;
      inherit (import ./user-options/options.nix) isDesktop;
      rustCratesOverlay = final: prev: {
        keifu = prev.rustPlatform.buildRustPackage {
          pname = "keifu";
          version = "0.1.5";

          src = prev.fetchCrate {
            pname = "keifu";
            version = "0.1.5";
            sha256 = "sha256-fo0c68H65/6GqOCQrkAEHvVssBL5n7ZL/XVcm4VIijo=";
          };

          cargoHash = "sha256-AyyLl9ZLMMikaeDvJhFXwAWgivi89gOqz52eyJZQTXQ=";

          nativeBuildInputs = [ prev.pkg-config ];
          buildInputs = [ prev.openssl ];

          env = {
            OPENSSL_NO_VENDOR = "1";
            OPENSSL_DIR = "${prev.openssl.dev}";
            OPENSSL_LIB_DIR = "${prev.openssl.out}/lib";
            OPENSSL_INCLUDE_DIR = "${prev.openssl.dev}/include";
          };
        };

        filetree = prev.rustPlatform.buildRustPackage {
          pname = "filetree";
          version = "0.3.5";

          src = prev.fetchCrate {
            pname = "filetree";
            version = "0.3.5";
            sha256 = "sha256-27LsAG15Rr6Gbm/oL+tIeDrU/xa52bbEocPWInx8cl8=";
          };

          cargoHash = "sha256-TZWIa4L70WpvGwTi8DIadKwXEubxn3OciSaWf9UULZA=";
        };
      };
      pkgs = (
        (
          nixpkgs.legacyPackages.${system}.extend (
            neovim-nightly-overlay.overlays.default
          )
        ).extend (zed.overlays.default)
      ).extend rustCratesOverlay;
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
            
            modules = [
              (import ./home-manager/default.nix { 
                inherit inputs;
                inherit username;
                inherit pkgs;
                inherit system;
                inherit isDesktop;
              })
            ];
          };
        };
        darwinConfigurations = {
          mac-config = nix-darwin.lib.darwinSystem {
            system = system;
            modules = [ 
              { system.primaryUser = username; }
              (import ./nix-darwin/default.nix { 
                inherit inputs;
                inherit username;
                inherit pkgs;
                inherit system;
                inherit isDesktop;
              })
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
    }
  );
}

