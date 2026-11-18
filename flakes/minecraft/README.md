# Minecraft environments

PrismLauncher、Vanilla、1.7.10の二つのMOD環境、1.20.1を管理する独立flake。
modules/に宣言と初期配置処理、docs/に復元手順、tests/にデータ保持の回帰検査を置く。
バージョン・Java・メモリ・資産ハッシュは親から移管した値を維持する。

## 利用

flakeのinputとしてこのディレクトリを指定し、`inputs.minecraft.homeModules.default` を
Home Managerのimportsへ追加する。親リポジトリは `gaming` profileから読み込む。
親はnixpkgsとHome Managerをfollowsで共有する。単独利用時はこのディレクトリの
flake.lockを使うので、更新時は単独と親の両方で検証する。
将来別リポジトリに移す場合も、このディレクトリ単位で移管できる。

## 復元とデータ

- [Vanilla・1.7.10・ローカル資産の復元と移行](docs/minecraft.md)
- [1.20.1の構成と復元](docs/minecraft-modern.md)

セーブ・認証情報・プレイ中に変更した設定は通常のデータ領域に置く。
定義には含めず、不足分の初期配置だけを行う。既存データは再適用で上書きしない。
セーブはPrismLauncherを終了して別領域へコピーし、バックアップからの復元を確認する。
既存インスタンスの衝突を検出した場合は自動移行せず、docsの手順で退避してから適用する。

## 検証（このディレクトリから）

```sh
nix flake check
python3 tests/test_prismix_persistence.py
```

永続化テストは一時HOMEで生成されたactivation断片を実行する。実ユーザーへswitchしない。
ローカルMODアーカイブはdocsの手順でNix storeに登録してからビルドする。
