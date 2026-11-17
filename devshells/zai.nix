{ pkgs }:
pkgs.mkShell {
  packages = [ pkgs.claude-code ];

  ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
  API_TIMEOUT_MS = "3000000";
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  DISABLE_AUTOUPDATER = "1";

  # Secrets are read at shell startup, never during Nix evaluation.
  shellHook = ''
    export CLAUDE_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/claude-zai"
    unset ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN
    unset CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
    export ANTHROPIC_MODEL="''${ZAI_MODEL:-glm-5.3-flash}"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_MODEL"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_MODEL"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_MODEL"
    export CLAUDE_CODE_SUBAGENT_MODEL="$ANTHROPIC_MODEL"

    export ANTHROPIC_AUTH_TOKEN="''${ZAI_API_KEY:-}"
    if [ -z "$ANTHROPIC_AUTH_TOKEN" ] && [ -t 0 ]; then
      read -r -s -p "Z.ai API key: " ANTHROPIC_AUTH_TOKEN
      printf '\n'
    fi
    if [ -z "$ANTHROPIC_AUTH_TOKEN" ]; then
      echo "Z.ai API key is missing. Set ZAI_API_KEY before nix develop." >&2
      exit 1
    fi
    echo "Z.ai backend ready. Run: claude"
  '';
}
