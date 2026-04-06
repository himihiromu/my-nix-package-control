# Docker Nix Test Environment

Docker 上で `flake.nix` の評価と Home Manager のビルド確認を行うための最小テスト環境です。

## 起動

```bash
docker compose up -d --build
```

コンテナへ入る場合:

```bash
docker compose exec nixos-test /root/.nix-profile/bin/bash
```

## テスト実行

### Nix / flake の基本確認
```bash
docker compose exec nixos-test /workspace/test-nix-env.sh
```

### Home Manager のビルド確認
```bash
docker compose exec nixos-test /workspace/test-home-manager.sh
```

### Home Manager の適用
```bash
docker compose exec nixos-test /workspace/apply-home-manager.sh
```

## 前提

- `user-options/options.nix` は変更せず、環境変数入力をそのまま利用します
- `USER`, `GIT_USERNAME`, `GIT_EMAIL`, `OPENAI_KEY` は必要に応じて `docker compose` 側から渡します
- main ブランチの `home-manager` ディレクトリ構成は維持したまま、Docker テスト導線だけを追加します
