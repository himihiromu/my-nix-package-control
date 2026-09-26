{
  pkgs,
}:
{
  installPackages = with pkgs; [
    vim
    git
    gh
    ghq
    peco
    docker
    curl
    chezmoi
    wireguard-tools
    wireguard-go
    htop
    bat
    bun
    ripgrep
    pik
    just
    jq
    fd
    nushell
    dust
    tmux
    bruno
    pandoc
    claude-code
    llmfit
    ollama
    # GNU coreutilsのRust実装。プレフィックスなしで ls, rm, cat 等を提供し、
    # per-user profileがPATH優先されるためシステムのcoreutilsを置き換える
    uutils-coreutils-noprefix
  ];
}
