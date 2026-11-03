{
  lib,
  pkgs,
  shellIntegrationPrograms,
  ...
}:
let
  orcaDirenv = pkgs.writeShellApplication {
    name = "orca-direnv";
    runtimeInputs = [ pkgs.direnv ];
    text = ''
      if [[ $# -eq 0 ]]; then
        echo 'Usage: orca-direnv <command> [args...]' >&2
        exit 64
      fi
      exec direnv exec . "$@"
    '';
  };

  generatedPrograms = lib.genAttrs shellIntegrationPrograms (_: {
    enable = true;
  });

  programOverrides = {
    direnv = {
      nix-direnv.enable = true;
    };

    yazi.shellWrapperName = "y";

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

  # Orca の Command 欄は orca-direnv と起動する CLI を指定する。
  # direnv が未承認の .envrc を検出した場合は、agent も起動しない。
  home.packages = [ orcaDirenv ] ++ lib.mapAttrsToList (name: command:
    pkgs.writeShellApplication {
      name = "orca-${name}-direnv";
      text = ''
        exec ${orcaDirenv}/bin/orca-direnv ${lib.escapeShellArg command} "$@"
      '';
    }
  ) {
    codex = "codex";
    claude = "claude";
    opencode = "opencode";
    antigravity = "agy";
  };
}
