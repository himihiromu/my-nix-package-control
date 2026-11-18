final: prev: {
  # 同梱ライブラリを前提とする Codex のビルドで、
  # cargoSetupHook によるシステムライブラリ使用の強制を無効にする。
  codex = prev.codex.overrideAttrs (old: {
    dontCargoUseSystemLibs = true;
  });

  # cargoSetupHook が要求するシステムの libgit2 を fff.nvim に渡す。
  vimPlugins = prev.vimPlugins.extend (
    vimFinal: vimPrev: {
      fff-nvim = vimPrev.fff-nvim.override {
        rustPlatform = prev.rustPlatform // {
          buildRustPackage =
            args:
            prev.rustPlatform.buildRustPackage (
              args
              // {
                buildInputs = (args.buildInputs or [ ]) ++ [ prev.libgit2 ];
              }
            );
        };
      };
    }
  );

}
