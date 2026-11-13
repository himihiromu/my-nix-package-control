# 実ユーザーへ適用せず、Prismix の生成ファイルと activation 断片を検証する。
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfreePredicate =
      pkg:
      builtins.elem pkg.name [
        "Industrial-1.7.10-Trial-assets.tar.gz"
        "Industry-Magic-1.7.10-Trial-assets.tar.gz"
      ];
  };
  inherit (pkgs) lib;
  mkHome =
    version:
    flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        flake.inputs.prismix.homeModules.default
        ../home-manager/install-package/minecraft.nix
        {
          home.username = "prismix-test";
          home.homeDirectory = "/tmp/prismix-fixture-home";
          home.stateVersion = "24.05";
          programs.prismlauncher.instances.Vanilla.minecraft.version = lib.mkForce version;
        }
      ];
    };
  home = mkHome "26.3";
  # 最新版を再解決せず、設定変更時にも saves を維持することを検査するための値。
  updated = mkHome "26.2";
  metadata =
    home:
    let
      cfg = home.config;
      prism = cfg.programs.prismlauncher;
      files = lib.filterAttrs (name: _: lib.hasInfix "/PrismLauncher/" name) cfg.home.file;
    in
    assert
      builtins.attrNames prism.instances == [
        "Industrial-1.7.10-Trial"
        "Industry-Magic-1.20.1"
        "Industry-Magic-1.7.10-Trial"
        "Vanilla"
      ];
    assert lib.all
      (
        name:
        let
          instance = prism.instances.${name};
        in
        instance.minecraft.version == "1.7.10"
        && instance.mod.loader.name == "forge"
        && instance.mod.loader.version == "10.13.4.1614"
        && instance.config.java.path == "${pkgs.jdk8}/bin/java"
        && instance.config.java.mem.max == 6144
      )
      [
        "Industrial-1.7.10-Trial"
        "Industry-Magic-1.7.10-Trial"
      ];
    assert prism.instances.Vanilla.mod.loader.name == null;
    assert prism.instances.Vanilla.mod.mods == [ ];
    assert
      prism.instances.Vanilla.config.java.mem == {
        min = 1024;
        max = 4096;
        permSize = null;
        warn = null;
      };
    assert lib.all (file: !file.force) (builtins.attrValues files);
    assert lib.all (name: !(lib.hasInfix "/saves" name) && !(lib.hasInfix "accounts" name)) (
      builtins.attrNames files
    );
    {
      homeDirectory = cfg.home.homeDirectory;
      java = prism.instances.Vanilla.config.java.path;
      javaVersion = pkgs.jdk25.version;
      launcherVersion = prism.package.version;
      version = prism.instances.Vanilla.minecraft.version;
      checkScript = cfg.home.activation.prismixCheckVanilla.data;
      createScript = cfg.home.activation.prismixCreateVanillaSaves.data;
      legacyCheckScript = cfg.home.activation.prismixCheckLegacy.data;
      legacySeedScript = cfg.home.activation.prismixSeedLegacy.data;
      modernCheckScript = cfg.home.activation.prismixCheckModern.data;
      modernSeedScript = cfg.home.activation.prismixSeedModern.data;
      files = lib.mapAttrs (_: file: {
        source = toString file.source;
        inherit (file) onChange;
      }) files;
    };
in
{
  inherit (home) activationPackage;
  files = home.config.home-files;
  updatedFiles = updated.config.home-files;
  metadata = metadata home;
  updatedMetadata = metadata updated;
}
