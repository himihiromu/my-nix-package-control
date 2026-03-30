FROM nixos/nix:latest

# 必要なパッケージとflakes機能の有効化
RUN nix-channel --update && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# 作業ディレクトリの設定
WORKDIR /workspace

# gitとcurlとjqをインストール（flakeの依存関係のため）
RUN nix-env -iA nixpkgs.git nixpkgs.curl nixpkgs.jq

# ホストのファイルをコンテナにコピー
COPY . .

# デフォルトシェルをbashに設定
SHELL ["/bin/bash", "-c"]

# コンテナ起動時のコマンド
CMD ["bash"]