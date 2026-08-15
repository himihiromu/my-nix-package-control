{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs unstable no longer supports Intel macOS.
    nixpkgs-darwin-x86_64.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
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
    home-manager-x86_64 = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin-x86_64";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin-x86_64 = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin-x86_64";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-x86_64 = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin-x86_64";
    };

    takt = {
      url = "github:nrslib/takt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 実行時に --override-input で差し替える
    local-options = {
      url = "path:./user-options/options.nix";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-darwin-x86_64,
      nixos-wsl,
      neovim-nightly-overlay,
      flake-utils,
      home-manager,
      home-manager-x86_64,
      nix-darwin,
      nix-darwin-x86_64,
      nixvim,
      nixvim-x86_64,
      local-options,
      ...
    }@inputs:
    let
      options = import local-options;
      inherit (options) username isDesktop;
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
      mkPkgsFor =
        nixpkgsInput: system:
        (
          (
            (import nixpkgsInput {
              inherit system;
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgsInput.lib.getName pkg) [
                  "zsh-abbr"
                  "claude-code"
                ];
            }).extend
            (neovim-nightly-overlay.overlays.default)
          )
        ).extend
          rustCratesOverlay;
      mkPkgs = mkPkgsFor nixpkgs;
    in
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = mkPkgs system;
      in
      {
        formatter = pkgs.nixfmt;
        packages = {
          my-package = pkgs.buildEnv {
            name = "my-packages-list";
            paths = with pkgs; [
              git
              curl
              nixfmt
              neovim
            ];
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
              pkgs.yarn
              pkgs.typescript-language-server
              pkgs.typescript
            ];
            shellHook = ''
              echo "node version: $(node --version)"
              echo "npm version: $(npm --version)"
              echo "pnpm version: $(pnpm --version)"
              echo "bun version: $(bun --version)"
              echo "yarn version: $(yarn --version)"
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
          csharp = pkgs.mkShell {
            buildInputs = [
              pkgs.dotnet-sdk
              pkgs.omnisharp-roslyn
              # pkgs.dotnet-aspnetcore  # Web開発時に追加
            ];
            shellHook = ''
              echo "dotnet version: $(dotnet --version)"
              echo "OmniSharp version: $(omnisharp --version)"
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
    ))
    // (
      let
        linuxSystem = "x86_64-linux";
        darwinAarch64System = "aarch64-darwin";
        darwinX86_64System = "x86_64-darwin";
        linuxPkgs = mkPkgs linuxSystem;
        mkHomeConfiguration =
          nixpkgsInput: homeManagerInput: nixvimInput: system:
          let
            pkgs = mkPkgsFor nixpkgsInput system;
          in
          homeManagerInput.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              (import ./home-manager/default.nix {
                inherit
                  inputs
                  username
                  system
                  isDesktop
                  pkgs
                  ;
                nixvim = nixvimInput;
              })
            ];
          };
        mkDarwinConfiguration =
          nixpkgsInput: nixDarwinInput: system:
          let
            pkgs = mkPkgsFor nixpkgsInput system;
          in
          nixDarwinInput.lib.darwinSystem {
            inherit system;
            modules = [
              { system.primaryUser = username; }
              (import ./nix-darwin/default.nix {
                inherit
                  inputs
                  username
                  isDesktop
                  pkgs
                  system
                  ;
              })
            ];
          };
        darwinAarch64HomeConfiguration =
          mkHomeConfiguration nixpkgs home-manager nixvim
            darwinAarch64System;
        darwinX86_64HomeConfiguration =
          mkHomeConfiguration nixpkgs-darwin-x86_64 home-manager-x86_64 nixvim-x86_64
            darwinX86_64System;
        darwinAarch64Configuration = mkDarwinConfiguration nixpkgs nix-darwin darwinAarch64System;
        darwinX86_64Configuration =
          mkDarwinConfiguration nixpkgs-darwin-x86_64 nix-darwin-x86_64
            darwinX86_64System;
      in
      {
        nixosConfigurations = {
          nixos-wsl = nixpkgs.lib.nixosSystem {
            system = linuxSystem;
            modules = [
              nixos-wsl.nixosModules.default
              {
                system.stateVersion = "24.05";
                wsl.enable = true;
              }
            ];
          };

          nixos = nixpkgs.lib.nixosSystem {
            system = linuxSystem;
            modules = [
              { _module.args = { inherit username isDesktop; }; }
              ./nixos/configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.users.${username} = import ./home-manager/default.nix {
                  inherit
                    inputs
                    username
                    isDesktop
                    nixvim
                    ;
                  pkgs = linuxPkgs;
                  system = linuxSystem;
                };
              }
            ];
          };
        };

        homeConfigurations = {
          myHomeConfig = mkHomeConfiguration nixpkgs home-manager nixvim linuxSystem;
          myHomeConfig-darwin-aarch64 = darwinAarch64HomeConfiguration;
          myHomeConfig-darwin-x86_64 = darwinX86_64HomeConfiguration;

          # Backward-compatible alias for the existing Apple Silicon entry point.
          myHomeConfig-darwin = darwinAarch64HomeConfiguration;
        };

        darwinConfigurations = {
          mac-config-aarch64 = darwinAarch64Configuration;
          mac-config-x86_64 = darwinX86_64Configuration;

          # Backward-compatible alias for the existing Apple Silicon entry point.
          mac-config = darwinAarch64Configuration;
        };
      }
    );
}
