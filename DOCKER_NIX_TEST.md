# Docker Nix Test Environment

このディレクトリには、Nixの環境構築をテストするためのDocker環境が用意されています。

## セットアップ

### 1. Dockerコンテナのビルドと起動

```bash
# コンテナのビルドと起動
docker-compose up -d --build

# コンテナに入る
docker-compose exec nixos-test bash
```

### 2. テストの実行

コンテナ内で以下のコマンドを実行してNix環境をテストできます：

```bash
# テストスクリプトの実行
./test-nix-env.sh

# または個別にコマンドを実行
nix flake show
nix flake check --no-build
```

### 3. Flakeコマンドの実行例

```bash
# パッケージのビルド
nix build .#my-package

# アプリの実行
nix run .#update
nix run .#install

# 開発シェルの起動（設定されている場合）
nix develop
```

## ファイル構成

- `Dockerfile`: NixOSベースのDockerイメージ定義
- `docker-compose.yml`: Docker Compose設定
- `test-nix-env.sh`: Nix環境のテストスクリプト
- `flake.nix`: Nix Flake設定ファイル

## トラブルシューティング

### Flakesが有効でない場合

コンテナ内で以下を実行：
```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### コンテナの再起動

```bash
docker-compose down
docker-compose up -d --build
```

### キャッシュのクリア

```bash
docker-compose down -v  # ボリュームも削除
docker-compose up -d --build
```