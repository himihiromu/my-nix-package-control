{
  lib,
  system,
  isDesktop,
  isWsl ? false,
  requested ? null,
}:
let
  linux = lib.hasSuffix "-linux" system;
  darwin = lib.hasSuffix "-darwin" system;
  known = [
    "base"
    "gui-apps"
    "hyprland-tools"
    "hyprland"
    "gaming"
    "recording"
    "darwin"
  ];
  legacy = [
    "base"
  ]
  ++ lib.optional darwin "darwin"
  ++ lib.optional isDesktop "gui-apps"
  ++ lib.optionals (linux && isDesktop) [
    "hyprland-tools"
    "gaming"
  ]
  ++ lib.optionals (linux && isDesktop && !isWsl) [
    "hyprland"
    "recording"
  ];
  selected =
    if requested == null then
      legacy
    else if builtins.isList requested then
      [ "base" ] ++ requested
    else
      fail "Expected a list of profile names.";
  fail = message: throw ("local-options.homeProfiles: " + message);
in
if
  !builtins.isList selected || !lib.all (p: builtins.isString p && builtins.elem p known) selected
then
  fail "Expected a list of base, gui-apps, hyprland-tools, hyprland, gaming, recording, darwin."
else if
  !linux
  && lib.any (p: builtins.elem p selected) [
    "hyprland-tools"
    "hyprland"
    "gaming"
    "recording"
  ]
then
  fail "Hyprland, gaming and recording profiles require Linux."
else if
  isWsl
  && lib.any (p: builtins.elem p selected) [
    "hyprland"
    "recording"
  ]
then
  fail "Hyprland sessions and recording integration require a physical Linux session. Use gui-apps for WSLg."
else if !darwin && builtins.elem "darwin" selected then
  fail "darwin requires macOS."
else
  lib.unique selected
