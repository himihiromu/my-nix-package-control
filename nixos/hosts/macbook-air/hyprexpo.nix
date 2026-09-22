{ lib, fetchFromGitHub, hyprlandPlugins, meson, ninja }:

# HyprExpo's upstream compatibility pin for Hyprland 0.56.1/0.56.2.
# Build with the same nixpkgs Hyprland headers and dependencies as the host.
hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "hyprexpo";
  version = "0-unstable-5891014";
  src = fetchFromGitHub {
    owner = "sandwichfarm";
    repo = "hyprexpo";
    rev = "5891014c611e1bd56d0121143f0221d46b5c0967";
    hash = "sha256-86gJ8YixG+FeEcnkGHc0O3eCemoDLe9/cOa21VZKdQM=";
  };
  nativeBuildInputs = [ meson ninja ];
  doCheck = true;
  meta = {
    description = "Workspace overview for Hyprland";
    homepage = "https://github.com/sandwichfarm/hyprexpo";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
}
