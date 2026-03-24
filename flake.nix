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

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 実行時に --override-input で差し替える
    local-options = {
      url = "path:./user-options/options.nix";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, nixos-wsl, neovim-nightly-overlay, flake-utils, home-manager, nix-darwin, nixvim, local-options, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (
    system:
    let
      options = import local-options;
      inherit (options) username;
      inherit (options) isDesktop;
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
          (import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "zsh-abbr"
            ];
          }).extend (
            neovim-nightly-overlay.overlays.default
          )
        )
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
                inherit nixvim;
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
      devShells = {
        python = pkgs.mkShell {
          buildInputs = [
            pkgs.python314
            pkgs.uv
          ];
          shellHook = ''
            echo "uv version: $(uv --version)"
            echo "python version: $(python --version)"
          '';
        };
        js = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs_24
            pkgs.pnpm
            pkgs.bun
            pkgs.typescript-language-server
            pkgs.typescript
          ];
          shellHook = ''
            echo "node version: $(node --version)"
            echo "npm version: $(npm --version)"
            echo "pnpm version: $(pnpm --version)"
            echo "bun version: $(bun --version)"
          '';
        };
        java21 = pkgs.mkShell {
          buildInputs = [
            pkgs.gradle_9
            pkgs.maven
            pkgs.javaPackages.compiler.semeru-bin.jdk-21
          ];
          shellHook = ''
            echo "gradle version: $(gradle --version)"
            echo "maven version: $(maven --version)"
            echo "java version: $(java --version)"
            echo "javac version: $(javac --version)"
          '';
        };
        java8 = pkgs.mkShell {
          buildInputs = [
            pkgs.gradle_9
            pkgs.maven
            pkgs.javaPackages.compiler.semeru-bin.jdk-8
          ];
          shellHook = ''
            echo "gradle version: $(gradle --version)"
            echo "maven version: $(maven --version)"
            echo "java version: $(java --version)"
            echo "javac version: $(javac --version)"
          '';
        };
        go = pkgs.mkShell {
          buildInputs = [
            pkgs.go
            pkgs.gotools
            pkgs.golangci-lint
          ];
          shellHook = ''
            echo "go version: $(go version)"
            echo "golangci-lint version: $(golangci-lint --version)"
            echo $GOPATH
          '';
        };
        kotlin = pkgs.mkShell {
          buildInputs = [
            pkgs.kotlin
            pkgs.gradle_9
            pkgs.maven
            pkgs.javaPackages.compiler.semeru-bin.jdk-21
          ];
          shellHook = ''
            echo "gradle version: $(gradle --version)"
            echo "maven version: $(mvn -v)"
            echo "java version: $(java --version)"
            echo "javac version: $(javac --version)"
            echo "kotlin version: $(kotlin -version)"
          '';
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

