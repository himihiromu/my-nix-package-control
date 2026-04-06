FROM nixos/nix:latest

# flakes を有効化し、テスト実行に必要な最小ツールだけを入れる
RUN mkdir -p /etc/nix && \
    printf 'experimental-features = nix-command flakes\n' >> /etc/nix/nix.conf && \
    nix-channel --update && \
    nix-env -iA nixpkgs.bash nixpkgs.git nixpkgs.curl nixpkgs.jq nixpkgs.coreutils

WORKDIR /workspace

# ホスト側のリポジトリを volume mount して使う前提。
# ここではイメージを軽く保つため COPY は行わない。
SHELL ["/root/.nix-profile/bin/bash", "-lc"]

CMD ["/root/.nix-profile/bin/bash"]
