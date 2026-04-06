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

## 想定する用途

- Docker 上で flake の評価が通るか確認する
- Home Manager 設定のビルド可否を確認する
- ローカル環境を直接汚さずに Nix 実行テストを行う

## 補足

- イメージ build 時に repository 全体は COPY せず、volume mount 前提で扱います
- コンテナ内 shell は `/root/.nix-profile/bin/bash` を利用します
- Nix store は volume 化してキャッシュを保持します
