# Called by checks.nix with anonymous fixture configurations.
{ configurations, username }:
let
  check =
    host:
    let
      nixos = configurations.${host};
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
