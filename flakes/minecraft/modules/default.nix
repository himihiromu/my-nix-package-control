{
  config,
  lib,
  pkgs,
  ...
}:
let
  dataDir = "${config.xdg.dataHome}/PrismLauncher";
  vanillaDir = "${dataDir}/instances/Vanilla";
  java = "${pkgs.jdk25}/bin/java";
in
{
  imports = [
    ./legacy.nix
    ./modern.nix
  ];

  programs.prismlauncher = {
    enable = true;
    package = pkgs.prismlauncher.override {
      jdks = [
        pkgs.jdk25
        pkgs.jdk8
        pkgs.jdk17
      ];
    };
    config.java.path = java;

    instances.Vanilla = {
      # Mojang version_manifest_v2.json を確認: 2026-11-10。Java 25 が必要。
      minecraft.version = "26.3";
      mod.loader.name = null;
      mod.mods = [ ];
      config.java = {
        path = java;
        mem = {
          min = 1024;
          max = 4096;
        };
      };
      # Prismix v0.1.0 は java.path に OverrideJavaArgs を設定するため補完する。
      extraConfig.OverrideJavaLocation = true;
    };
  };

  # Prismix は .hm_* のみを Store へリンクし、実際の設定は通常ファイルへ
  # マージ/コピーする。既存の同名インスタンスは自動的に取り込まない。
  home.activation.prismixCheckVanilla = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    for path in ${
      lib.escapeShellArgs [
        dataDir
        "${dataDir}/instances"
        vanillaDir
        "${vanillaDir}/minecraft"
        "${vanillaDir}/minecraft/saves"
      ]
    }; do
      if [ -L "$path" ] || { [ -e "$path" ] && [ ! -d "$path" ]; }; then
        echo "Prismix: 通常ディレクトリではないため変更を中止します: $path" >&2
        exit 1
      fi
    done
    if [ -d ${lib.escapeShellArg vanillaDir} ] && ! { [ -L ${lib.escapeShellArg "${vanillaDir}/.hm_instance.cfg"} ] && [ -L ${lib.escapeShellArg "${vanillaDir}/.hm_mmc-pack.json"} ]; }; then
      echo "Prismix: 既存の Vanilla は自動変更しません。README の競合時の手順を確認してください。" >&2
      exit 1
    fi
    for path in ${
      lib.escapeShellArgs [
        "${dataDir}/prismlauncher.cfg"
        "${vanillaDir}/instance.cfg"
        "${vanillaDir}/mmc-pack.json"
      ]
    }; do
      if [ -L "$path" ] || { [ -e "$path" ] && [ ! -f "$path" ]; }; then
        echo "Prismix: 通常ファイルではない設定の変更を中止します: $path" >&2
        exit 1
      fi
    done
    if [ -e ${lib.escapeShellArg "${vanillaDir}/.minecraft"} ] || [ -L ${lib.escapeShellArg "${vanillaDir}/.minecraft"} ]; then
      echo "Prismix: 既存の .minecraft は自動変更しません。README を確認してください。" >&2
      exit 1
    fi
  '';

  # mkdir -p のみ。ワールド・認証情報は home.file の管理対象にしない。
  home.activation.prismixCreateVanillaSaves = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p -- ${lib.escapeShellArg "${vanillaDir}/minecraft/saves"}
  '';
}
