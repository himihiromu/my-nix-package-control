# nix-test-run ブランチ整理メモ

対象 issue: #7 作業途中ブランチの差分を整理して Nix 実行テストの継続方針を固める
対象ブランチ: `origin/nix-test-run`

## 結論

`nix-test-run` ブランチは、Nix 実行テストを進めるための試行内容と、一時ファイル・検証補助ファイル・環境依存差分が混在している状態です。

そのため、このブランチをそのまま main へ寄せるのではなく、まず以下の単位で整理するのが適切です。

1. **テスト実行のために本当に必要な差分**
2. **README / 手順書として残すべき差分**
3. **一時ファイル / 不要差分 / 環境依存差分**

## 観測できた差分の特徴

`main..origin/nix-test-run` では、以下のような差分が確認できました。

### 1. Nix 実行テストの本体候補
- `flake.nix`
- `flake.lock`
- `home-manager/default.nix`
- `nix-darwin/default.nix`
- `nix-darwin/config/system.nix`
- `user-options/options.nix`

このあたりは、本来の設定変更として精査対象にする価値があります。

### 2. テスト実行補助・検証用ファイル
- `DOCKER_NIX_TEST.md`
- `Dockerfile`
- `docker-compose.yml`
- `apply-home-manager.sh`
- `run-chrome.sh`
- `test-home-manager.sh`
- `test-nix-env.sh`

このあたりは、Nix 実行テストの導線を作るための補助資産として扱えます。

### 3. 明らかに整理対象の差分
- `*.Zone.Identifier`
- `nix-darwin/.default.nix.swp`
- `result`
- `test.txt`
- `flake-backup.nix`
- `flake.nix.backup`
- `nix-packages.list` の巨大差分

これらは、意図のある成果物と一時生成物が混ざっている可能性が高く、優先的に切り分けるべきです。

## 未完了箇所の見立て

現状の `nix-test-run` は、以下が未整理です。

- テストの主目的が README 上で説明されていない
- どの差分が恒久対応で、どの差分が検証専用なのかが分離されていない
- 生成物 / バックアップ / Windows 由来メタデータが混在している
- main に持ち込みたい変更と、持ち込むべきでない変更の境界が曖昧

## 継続方針

このブランチを続ける場合、次は以下の順序が安全です。

### Step 1. 不要差分の除外
- `*.Zone.Identifier` を除外
- swap / backup / result などの一時ファイルを除外
- 検証結果の dump で main に不要なものを切り離す

### Step 2. テスト導線と本体設定を分ける
- Docker / shell script / 実験手順を補助層として整理
- `flake.nix` / `home-manager` / `nix-darwin` 側の本体差分を別観点で再確認

### Step 3. README と検証シナリオを整備
- 何をテストしたいブランチなのか明確化
- Linux / macOS での確認対象を整理
- 期待する成功条件を定義

## 次の issue との関係

この整理結果から、以下の issue に自然につながります。

- #8 不要ファイル・一時ファイルの整理
- #9 flake.nix と各設定レイヤーの責務見直し
- #10 README に Nix 実行テスト手順と前提条件を補完
- #11 Nix 実行テストを回すための検証シナリオ整理
- #12 本実装変更の洗い出し

## まとめ

`nix-test-run` ブランチは、実行テストの方向性自体は有益ですが、現状では **検証資産・本体差分・一時ファイルが混在している途中状態** です。

まずは「何を main に持っていくか」を整理するための棚卸しを行い、その後に不要差分除去とテスト手順整理へ進むのが妥当です。
