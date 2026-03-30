{
  description = "Simple Home Manager test configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    username = "himihiromu";
  in
  {
    homeConfigurations = {
      "${username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            home.stateVersion = "24.05";
            
            home.packages = with pkgs; [
              git
              vim
              python3
              python3Packages.pip
              curl
              wget
              htop
            ];
            
            programs.vim = {
              enable = true;
              extraConfig = ''
                set number
                set expandtab
                set tabstop=2
                set shiftwidth=2
                syntax on
              '';
            };
            
            programs.git = {
              enable = true;
              userName = "himihiromu";
              userEmail = "himihiromu@icloud.com";
            };
            
            programs.bash = {
              enable = true;
              bashrcExtra = ''
                alias ll='ls -la'
                alias gs='git status'
                alias py='python3'
              '';
            };
            
            programs.home-manager.enable = true;
          }
        ];
      };
    };
  };
}