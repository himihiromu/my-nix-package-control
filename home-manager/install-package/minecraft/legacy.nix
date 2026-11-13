{
  config,
  lib,
  pkgs,
  ...
}:
let
  manifestFile = ./legacy-manifest.json;
  manifest = builtins.fromJSON (builtins.readFile manifestFile);
  dataDir = "${config.xdg.dataHome}/PrismLauncher";
  helper = "${pkgs.python3}/bin/python3 ${./assets.py}";
  arguments = "--manifest ${manifestFile} --data-dir ${lib.escapeShellArg dataDir}";
  assets = pkgs.runCommand "minecraft-legacy-assets" { nativeBuildInputs = [ pkgs.gnutar ]; } (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        id: spec:
        let
          archive = pkgs.requireFile {
            name = spec.archiveName;
            sha256 = spec.archiveSha256;
            message = ''
              旧MinecraftのローカルMOD資産が必要です。
              minecraft-legacy-cache を実行してから再ビルドしてください。
              初回は docs/minecraft.md の資産登録手順を参照してください。
            '';
          };
        in
        ''
          mkdir -p "$out/${id}"
          tar -xzf ${archive} -C "$out/${id}"
        ''
      ) manifest
    )
  );
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "minecraft-legacy-cache";
      runtimeInputs = [ pkgs.nix ];
      text = ''
        exec ${helper} cache --manifest ${manifestFile} "$@"
      '';
    })
  ];

  programs.prismlauncher.instances = lib.mapAttrs (_: spec: {
    minecraft.version = "1.7.10";
    mod.loader = {
      name = "forge";
      version = "10.13.4.1614";
    };
    # 配下の1.7.10/も必要。Prismixの平坦なmod.modsではなく通常ファイルで初期配置する。
    mod.mods = [ ];
    config.java = {
      path = "${pkgs.jdk8}/bin/java";
      args = [ ];
      mem = {
        min = 1024;
        max = 6144;
      };
    };
    extraConfig = {
      name = spec.displayName;
      OverrideJavaLocation = true;
      AutomaticJavaSwitch = false;
      AutomaticJavaDownload = false;
    };
  }) manifest;

  # ディスクは評価時に読まない。実ユーザーの既存構成は書き込み境界前に照合する。
  home.activation.prismixCheckLegacy = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${helper} check ${arguments}
  '';
  # ランチャー設定をPrismixがマージする前に、元設定を保管して不足資産だけ補う。
  # config/options.txtは既存内容を優先し、savesやaccounts.jsonには書き込まない。
  home.activation.prismixSeedLegacy =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        run ${helper} seed ${arguments} --assets ${assets}
      '';
}
