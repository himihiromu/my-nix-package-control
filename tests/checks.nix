{
  pkgs,
  system,
  inputs,
  mkNixos,
  mkHomeWith,
}:
let
  inherit (pkgs) lib;
  assertion = name: result: builtins.deepSeq result (pkgs.runCommand name { } "touch $out");
  configurations = isDesktop: {
    nixos = mkNixos {
      hostModule = ../nixos/hosts/nixos;
      inherit isDesktop;
      username = "nix-test";
      homeProfiles = null;
    };
    macbook-air = mkNixos {
      hostModule = ../nixos/hosts/macbook-air;
      inherit isDesktop;
      username = "nix-test";
      homeProfiles = null;
    };
    nixos-wsl = mkNixos {
      hostModule = ../nixos/hosts/nixos-wsl;
      inherit isDesktop;
      username = "nix-test";
      isWsl = true;
      homeProfiles = null;
    };
  };
  wsl =
    isDesktop:
    import ./check-wsl.nix {
      inherit isDesktop;
      configurations = configurations isDesktop;
      username = "nix-test";
    };
  gui =
    (mkHomeWith {
      inherit system;
      username = "nix-test";
      isDesktop = false;
      homeProfiles = [ "gui-apps" ];
    }).config;
  game =
    (mkHomeWith {
      inherit system;
      username = "nix-test";
      isDesktop = false;
      homeProfiles = [ "gaming" ];
    }).config;
  names = c: map (p: p.pname or p.name) c.home.packages;
  independent =
    assert gui.programs.zed-editor.enable;
    assert !(gui.programs.prismlauncher.enable or false);
    assert !gui.wayland.windowManager.hyprland.enable;
    assert builtins.elem "chatgpt" (names gui);
    assert game.programs.prismlauncher.enable;
    assert !game.programs.zed-editor.enable;
    assert !(builtins.elem "chatgpt" (names game));
    true;
  python = pkgs.python3.withPackages (ps: [ ps.websockets ]);
in
{
  local-options = assertion "local-options-check" (import ./check-local-options.nix);
  unfree-policy = assertion "unfree-policy-check" (
    let
      common = import ../lib/nixpkgs-policy.nix { inherit lib; };
      steam = import ../lib/nixpkgs-policy.nix {
        inherit lib;
        extraAllowedNames = [ "steam" ];
      };
    in
    assert !(common.allowUnfreePredicate { pname = "not-approved"; });
    assert common.allowUnfreePredicate {
      pname = "codex";
      name = "Industrial-1.7.10-Trial-assets.tar.gz";
    };
    assert !(common.allowUnfreePredicate { pname = "steam"; });
    assert steam.allowUnfreePredicate { pname = "steam"; };
    true
  );
  profiles = assertion "profile-selection-check" (import ./check-profiles.nix { inherit lib; });
  verification-runner =
    pkgs.runCommand "verification-runner-check" { nativeBuildInputs = [ pkgs.python3 ]; }
      ''
        mkdir scripts tests
        cp ${../scripts/verify.py} scripts/verify.py
        cp ${./test_verify.py} tests/test_verify.py
        python tests/test_verify.py
        touch $out
      '';
  obs-control = pkgs.runCommand "obs-control-check" { nativeBuildInputs = [ python ]; } ''
    cp -r ${../home-manager} home-manager
    mkdir tests
    cp ${./test_obs_control.py} tests/test_obs_control.py
    python tests/test_obs_control.py
    touch $out
  '';
}
// lib.optionalAttrs (system == "x86_64-linux") {
  wsl-cli = assertion "wsl-cli-check" (wsl false);
  wsl-desktop = assertion "wsl-desktop-check" (wsl true);
  overlays = assertion "nixos-overlay-check" (
    import ./check-nixos-overlays.nix {
      configurations = configurations false;
      username = "nix-test";
    }
  );
  profile-composition = assertion "profile-composition-check" independent;
  minecraft-metadata = inputs.minecraft.checks.${system}.metadata;
}
