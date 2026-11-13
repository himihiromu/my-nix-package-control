{
  config,
  lib,
  pkgs,
  ...
}:
let
  lockFile = ./modern-lock.json;
  lock = builtins.fromJSON (builtins.readFile lockFile);
  id = lock.instanceId;
  dataDir = "${config.xdg.dataHome}/PrismLauncher";
  mods = map (
    mod:
    pkgs.fetchurl {
      name = mod.filename;
      inherit (mod) url;
      sha256 = mod.sha256;
    }
  ) lock.mods;
  assets = pkgs.runCommand "minecraft-modern-assets" { } ''
    mkdir -p "$out/${id}/mods"
    ${lib.concatMapStringsSep "\n" (mod: ''
      cp ${mod} "$out/${id}/mods/${mod.name}"
    '') mods}
  '';
  manifest = pkgs.writeText "minecraft-modern-seed.json" (
    builtins.toJSON {
      ${id} = {
        inherit (lock) minecraftVersion forgeVersion;
        language = "ja_jp";
        archiveName = "modern-lock.json";
        archiveSha256 = builtins.hashString "sha256" (builtins.readFile lockFile);
        files = builtins.listToAttrs (
          map (mod: {
            name = "mods/${mod.filename}";
            value = mod.sha256;
          }) lock.mods
        );
      };
    }
  );
  helper = "${pkgs.python3}/bin/python3 ${./assets.py}";
  arguments = "--manifest ${manifest} --data-dir ${lib.escapeShellArg dataDir}";
in
{
  programs.prismlauncher.instances.${id} = {
    minecraft.version = lock.minecraftVersion;
    mod.loader = {
      name = "forge";
      version = lock.forgeVersion;
    };
    # 通常ファイルとして配置し、ゲームから書き込むディレクトリを維持する。
    mod.mods = [ ];
    config.java = {
      path = "${pkgs.jdk17}/bin/java";
      args = [ ];
      mem = {
        min = 1024;
        max = 8192;
      };
    };
    extraConfig = {
      name = lock.displayName;
      OverrideJavaLocation = true;
      AutomaticJavaSwitch = false;
      AutomaticJavaDownload = false;
    };
  };
  home.activation.prismixCheckModern = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${helper} check ${arguments}
  '';
  home.activation.prismixSeedModern =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        run ${helper} seed ${arguments} --assets ${assets}
      '';
}
