{
  lib,
  shellIntegrationPrograms,
  ...
}:
let
  generatedPrograms = lib.genAttrs shellIntegrationPrograms (_: {
    enable = true;
  });

  programOverrides = {
    direnv = {
      nix-direnv.enable = true;
    };

    zoxide = {
      options = [
        "--cmd"
        "ls"
      ];
    };
  };
in
{
  programs = lib.recursiveUpdate generatedPrograms programOverrides;
}
