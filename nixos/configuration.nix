# NixOS Entry Point
# 設定は極力書かず、エントリーポイントとして利用する

{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./system/desktop.nix
    ./system/services.nix
    ./system/nix.nix
  ];

  # User
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
    ];
  };

  # Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

}
