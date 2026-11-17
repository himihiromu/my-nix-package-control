{ lib }:
let
  select =
    args:
    import ../home-manager/profiles/select.nix (
      {
        inherit lib;
        system = "x86_64-linux";
        isDesktop = true;
      }
      // args
    );
  succeeds = value: (builtins.tryEval (builtins.deepSeq value true)).success;
in
assert select { isDesktop = false; } == [ "base" ];
assert
  select { requested = [ "gui-apps" ]; } == [
    "base"
    "gui-apps"
  ];
assert
  select {
    requested = [
      "base"
      "gaming"
    ];
  } == [
    "base"
    "gaming"
  ];
assert
  select { isWsl = true; } == [
    "base"
    "gui-apps"
    "hyprland-tools"
    "gaming"
  ];
assert
  select { system = "aarch64-darwin"; } == [
    "base"
    "darwin"
    "gui-apps"
  ];
assert
  !(succeeds (select {
    requested = [ "unknown" ];
  }));
assert
  !(succeeds (select {
    isWsl = true;
    requested = [ "hyprland" ];
  }));
assert
  !(succeeds (select {
    system = "aarch64-darwin";
    requested = [ "gaming" ];
  }));
assert
  !(succeeds (select {
    requested = "gui-apps";
  }));
true
