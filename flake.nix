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
    prismix = {
      url = "git+https://codeberg.org/OliMoli/prismix?ref=refs/tags/v0.1.0";
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
      nixos-wsl,
      neovim-nightly-overlay,
      flake-utils,
      home-manager,
      nix-darwin,
      nixvim,
      local-options,
      ...
    }@inputs:
    let
      options = import ./lib/validate-options.nix (import local-options);
      inherit (options) username isDesktop;
      # Explicit in chezmoi's input; --impure remains a migration fallback.
      localSystem =
        options.system or (builtins.currentSystem
          or (throw "local-options: add system = \"x86_64-linux\" (or your Linux/Darwin system), or temporarily pass --impure. See README.md.")
        );
      overlays = [
        neovim-nightly-overlay.overlays.default
        (import ./overlays/fixes.nix)
        (import ./overlays { inherit inputs; })
      ];
      mkPkgs =
        system:
        import nixpkgs {
          inherit system overlays;
          config = import ./lib/nixpkgs-policy.nix {
            inherit (nixpkgs) lib;
            };
        };
      mkNixos =
        {
          hostModule,
          isWsl ? false,
          system ? "x86_64-linux",
        }:
        let
          pkgs = mkPkgs system;
        in
        nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            {
              _module.args = { inherit username isDesktop isWsl; };
              # NixOS 経由の Home Manager は useGlobalPkgs により
              # システムの pkgs を使うため、同じ overlay を適用する。
              nixpkgs.overlays = overlays;
            }
            ./nixos/configuration.nix
            hostModule
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                inherit
                  inputs
                  username
                  isDesktop
                  isWsl
                  system
                  ;
                homeProfiles = options.homeProfiles or null;
              };
              home-manager.users.${username} = ./home-manager/default.nix;
            }
          ]
          ++ (
            if isWsl then
              [ nixos-wsl.nixosModules.default ]
            else
              [
                ./nixos/system/physical-services.nix
              ]
          )
          ++ nixpkgs.lib.optionals (isDesktop && !isWsl) [
            ./nixos/system/desktop.nix
          ];
        };

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            isWsl = false;
            inherit
              inputs
              username
              isDesktop
              system
              ;
            homeProfiles = options.homeProfiles or null;
          };
          modules = [ ./home-manager/default.nix ];
        };
      mkDarwin =
        system:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              username
              isDesktop
              system
              ;
          };
          modules = [
            { system.primaryUser = username; }
            ./nix-darwin/default.nix
          ];
        };
    in
    {
      overlays.default = nixpkgs.lib.composeManyExtensions overlays;
      nixosConfigurations = {
        nixos = mkNixos { hostModule = ./nixos/hosts/nixos; };
        macbook-air = mkNixos { hostModule = ./nixos/hosts/macbook-air; };
        nixos-wsl = mkNixos {
          hostModule = ./nixos/hosts/nixos-wsl;
          isWsl = true;
        };
      };
      homeConfigurations =
        nixpkgs.lib.genAttrs (map (system: "myHomeConfig-${system}") flake-utils.lib.defaultSystems) (
          name: mkHome (nixpkgs.lib.removePrefix "myHomeConfig-" name)
        )
        // {
          myHomeConfig = mkHome localSystem;
        };
      darwinConfigurations = {
        mac-config-aarch64-darwin = mkDarwin "aarch64-darwin";
        mac-config-x86_64-darwin = mkDarwin "x86_64-darwin";
        mac-config = mkDarwin localSystem;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
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
        }
        // nixpkgs.lib.genAttrs [ "bash-abbrev-alias" "keifu" "filetree" "takt" ] (name: pkgs.${name})
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) chatgpt orca-ide ghostty-wayland-ime;
        };
        devShells = import ./devshells { inherit pkgs; };
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
