# 実行: nix eval --impure --json --file tests/check-nixos-overlays.nix
# 単体 Home Manager だけでなく、useGlobalPkgs を使う NixOS 経由も確認する。
let
  flake = builtins.getFlake (toString ../.);
  username = (import flake.inputs.local-options).username;
  check = host:
    let
      nixos = flake.packages.x86_64-linux.nixosConfigurations.${host};
      home = nixos.config.home-manager.users.${username};
      expected = "${nixos.pkgs.bash-abbrev-alias}/share/bash-abbrev-alias/abbrev-alias.plugin.bash";
    in
    assert nixos.config.home-manager.useGlobalPkgs;
    assert nixos.pkgs ? bash-abbrev-alias;
    assert nixos.pkgs ? keifu;
    assert nixos.pkgs ? filetree;
    assert toString home.xdg.configFile."bash/abbrev-alias.plugin.bash".source == expected;
    true;
in
{
  nixos = check "nixos";
  macbook-air = check "macbook-air";
}
