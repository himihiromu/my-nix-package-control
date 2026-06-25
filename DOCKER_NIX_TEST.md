# Docker Nix Test Environment

Docker 上で `flake.nix` の評価と Home Manager の build 確認を行うための最小テスト環境です。

## 起動

```bash
docker compose up -d --build
```

コンテナへ入る場合:

```bash
docker compose exec nixos-test /root/.nix-profile/bin/bash
```

## テスト実行

### 1. Nix / flake の基本確認
```bash
docker compose exec nixos-test /workspace/test-nix-env.sh
```

このスクリプトで確認すること:
- 現在の system が取得できること
- `nix --version` が通ること
- flakes が有効であること
- `nix flake metadata` が通ること

成功の目安:
- 最後に `Test completed successfully!` が出ること

### 2. Home Manager の評価確認
```bash
docker compose exec nixos-test /workspace/test-home-manager.sh
```

このスクリプトで確認すること:
- `nix run nixpkgs#home-manager` が利用できること
- `.#packages.<system>.homeConfigurations.myHomeConfig.activationPackage` の評価が通ること

成功の目安:
- `home-manager command available ✓`
- `Home Manager target evaluation ✓`
- 最後に `Test complete!` が出ること

### 3. Home Manager の適用
```bash
docker compose exec nixos-test /workspace/apply-home-manager.sh
```

これは評価確認の次段階で、実際に build してから `./result/activate` を実行します。
Docker テストではまず `test-home-manager.sh` で軽量に確認し、実 build が必要な場合に `apply-home-manager.sh` を使ってください。

## 前提

- `user-options/options.nix` は変更せず、環境変数入力をそのまま利用します
- `USER`, `GIT_USERNAME`, `GIT_EMAIL`, `OPENAI_KEY` は必要に応じて `docker compose` 側から渡します
- `USER` が未設定でも Docker テストが止まらないよう、Home Manager 系スクリプトでは `USER=tester` と一時 `HOME=/tmp/home-manager-test-home` を補完します
- main ブランチの `home-manager` ディレクトリ構成は維持したまま、Docker テスト導線だけを追加しています
- volume mount した `/workspace` は Git safe.directory として扱うよう、各テストスクリプト内で設定しています

## 既知事項

- `warning: Git tree '/workspace' is dirty`
  - volume mount した作業コピーを対象に評価しているため出ることがあります
- `repository path '/workspace' is not owned by current user`
  - Docker の bind mount を root で評価すると、flake が `git+file:///workspace` として解決され ownership チェックで失敗することがあります
  - Docker テスト用スクリプトでは `path:/workspace#...` を使って Git 経由の解決を避けています
- `home directory "/homeless-shelter" exists`
  - `nixos/nix` ベースイメージ上の非 sandbox build で、`/homeless-shelter` が残っていると purity チェックで失敗することがあります
  - Dockerfile とテストスクリプト側で `/homeless-shelter` を削除して回避しています
- `warning: the group 'nixbld' specified in 'build-users-group' does not exist`
  - Docker テストでは `test-home-manager.sh` / `apply-home-manager.sh` 側で `--option build-users-group ''` を付けて回避しています
  - 恒久対応は別 issue で対応予定です
  - issue: <https://github.com/himihiromu/my-nix-package-control/issues/20>

## 補足

README に記載しているコマンドは、上記 3 つのスクリプトに対応しています。
まずは `test-nix-env.sh` と `test-home-manager.sh` が通ることを Docker テストの基準にします。
