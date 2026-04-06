FROM nixos/nix:latest

# flakes を有効化し、Docker 上での最小テストに必要なコマンドだけを入れる
RUN mkdir -p /etc/nix && \
    printf 'experimental-features = nix-command flakes\n' >> /etc/nix/nix.conf && \
    nix-channel --update && \
    nix-env -iA nixpkgs.bash nixpkgs.git nixpkgs.curl nixpkgs.jq nixpkgs.coreutils

WORKDIR /workspace

# repository は volume mount 前提で扱う
SHELL ["/root/.nix-profile/bin/bash", "-lc"]
CMD ["/root/.nix-profile/bin/bash"]
