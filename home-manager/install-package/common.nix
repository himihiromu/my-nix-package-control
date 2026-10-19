{
  pkgs,
}:
{
  installPackages = with pkgs; [
    awscli2
    vim
    git
    gh
    ghq
    peco
    docker
    curl
    chezmoi
    mise
    wireguard-tools
    wireguard-go
    (net-tools.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        rm -f \
          $out/bin/hostname \
          $out/bin/dnsdomainname \
          $out/bin/ypdomainname \
          $out/bin/nisdomainname \
          $out/bin/domainname \
          $out/share/man/man1/hostname.1*
      '';
    }))
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
    codex
    llmfit
    ollama
    filetree
    keifu
    bash-abbrev-alias
    # GNU coreutilsのRust実装。プレフィックスなしで ls, rm, cat 等を提供し、
    # per-user profileがPATH優先されるためシステムのcoreutilsを置き換える
    # darwinのnet-toolsはsymlinkJoinでpostInstallが効かずhostnameが衝突するため優先度を上げる
    (lib.hiPrio uutils-coreutils-noprefix)
  ];
}
