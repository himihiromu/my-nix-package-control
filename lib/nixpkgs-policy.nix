{ lib, extraAllowedNames ? [ ] }:
{
  allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) ([
      "zsh-abbr" "claude-code" "vscode" "google-chrome" "chatgpt"
      "zoom" "discord" "discord-unwrapped"
    ] ++ extraAllowedNames)
    || builtins.elem (pkg.name or "") [
      "Industrial-1.7.10-Trial-assets.tar.gz"
      "Industry-Magic-1.7.10-Trial-assets.tar.gz"
    ];
}
