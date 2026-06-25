FROM nixos/nix:latest

# flakes を有効化し、Docker 上での最小テストに必要なコマンドだけを入れる
# `nixos/nix` 側で入っている git-minimal と衝突するため、ここでは git を追加しない。
# ベースイメージに user/group 管理コマンドが無い場合があるため、nixbld 用設定は可能なときだけ有効にする。
RUN mkdir -p /etc/nix && \
    printf 'experimental-features = nix-command flakes\n' >> /etc/nix/nix.conf && \
    nix-channel --update && \
    nix-env -iA nixpkgs.bash nixpkgs.curl nixpkgs.jq nixpkgs.coreutils && \
    rm -rf /homeless-shelter && \
    if command -v groupadd >/dev/null 2>&1 && command -v useradd >/dev/null 2>&1; then \
      groupadd -g 30000 nixbld && \
      for i in $(seq 1 10); do useradd -u $((30000 + i)) -g nixbld -M -d /var/empty -s /usr/sbin/nologin "nixbld${i}" || true; done && \
      printf 'build-users-group = nixbld\n' >> /etc/nix/nix.conf; \
    fi

WORKDIR /workspace

# repository は volume mount 前提で扱う
SHELL ["/root/.nix-profile/bin/bash", "-lc"]
CMD ["/root/.nix-profile/bin/bash"]
