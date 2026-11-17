{ pkgs, inputs }:
inputs.takt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    substituteInPlace "$out/lib/node_modules/takt/dist/infra/claude-headless/headless-spawn.js" \
      --replace-fail \
        "const HEADLESS_MAX_BUFFER_BYTES = 10 * 1024 * 1024;" \
        "const HEADLESS_MAX_BUFFER_BYTES = 64 * 1024 * 1024;"
  '';
})
