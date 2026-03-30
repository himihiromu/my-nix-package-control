{
  description = "Unified configuration with nix-darwin, home-manager, and nixos";

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
  let
    inherit (import ./user-options/options.nix) username;
    
    # システム別のpkgs定義
    darwinSystem = "aarch64-darwin";
    linuxSystem = "x86_64-linux";
    
    # Darwin用のpkgs
    pkgsDarwin = nixpkgs.legacyPackages.${darwinSystem}.extend (neovim-nightly-overlay.overlays.default);
    
    # Linux用のpkgs
    pkgsLinux = nixpkgs.legacyPackages.${linuxSystem}.extend (neovim-nightly-overlay.overlays.default);
  in
  {
    # Darwin configurations
    darwinConfigurations = {
      "kawarimidoll-darwin" = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        modules = [ 
          home-manager.darwinModules.home-manager
          ./nix-darwin/default.nix
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${username} = import ./home-manager/default.nix;
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };
    };

    # NixOS configurations (for WSL)
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        modules = [
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "24.05";
            wsl.enable = true;
          }
        ];
      };
    };

    # Home Manager configurations (スタンドアロン用)
    homeConfigurations = {
      "${username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsLinux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home-manager/default.nix ];
      };
      
      "${username}-darwin" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsDarwin;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home-manager/default.nix ];
      };
    };
  } // flake-utils.lib.eachDefaultSystem (
    system:
    let
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
      };
      
      # Apps for various operations
      apps = {
        update = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "update-script" ''
              set -e
              echo "Updating flake..."
              nix --extra-experimental-features nix-command --extra-experimental-features flakes flake update
              echo "Update complete!"
            ''
          );
          meta = {
            description = "Update flake.lock file";
          };
        };
        
        home-switch = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "home-switch-script" ''
              set -e
              echo "Switching Home Manager configuration for ${username}..."
              if [[ "$OSTYPE" == "darwin"* ]]; then
                nix --extra-experimental-features nix-command --extra-experimental-features flakes run home-manager/master -- switch --flake .#${username}-darwin
              else
                nix --extra-experimental-features nix-command --extra-experimental-features flakes run home-manager/master -- switch --flake .#${username}
              fi
              echo "Home configuration applied!"
            ''
          );
          meta = {
            description = "Switch to Home Manager configuration";
          };
        };
        
        home-build = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "home-build-script" ''
              set -e
              echo "Building Home Manager configuration for ${username}..."
              if [[ "$OSTYPE" == "darwin"* ]]; then
                nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#homeConfigurations.${username}-darwin.activationPackage
              else
                nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#homeConfigurations.${username}.activationPackage
              fi
              echo "Build complete! Result is in ./result"
            ''
          );
          meta = {
            description = "Build Home Manager configuration";
          };
        };
        
        darwin-switch = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "darwin-switch-script" ''
              set -e
              echo "Switching Darwin configuration..."
              darwin-rebuild switch --flake .#kawarimidoll-darwin
              echo "Darwin configuration applied!"
            ''
          );
          meta = {
            description = "Switch to Darwin configuration";
          };
        };
        
        install = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "install-script" ''
              set -e
              echo "Installing packages..."
              nix --extra-experimental-features nix-command --extra-experimental-features flakes profile install .#my-package
              echo "Installation complete!"
            ''
          );
          meta = {
            description = "Install packages to profile";
          };
        };
      };
    }
  );
}