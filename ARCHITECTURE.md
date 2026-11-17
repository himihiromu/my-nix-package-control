# Nix環境の設計と管理担当

NixOS・Home Manager・nix-darwin・chezmoiでLinux/macOS環境を管理する。
通常のモジュールと明示的なimportsを使い、独自enableオプションは必要な場合に限る。

## 構成の入口

- flake.nix: inputsと公開する構成の接続。NixOSホストのsystemは明示する。
- lib/nixpkgs-policy.nix: 共通の非フリーパッケージ許可方針。Steamなどの追加分は入口ごとに指定する。
- overlays/: 上流パッケージへの修正とpkgs/のローカルパッケージの接続。
- pkgs/: パッケージ作成。単独で評価・ビルドできるものを置く。
- devshells/: 開発環境。秘密情報は評価時に読み込まず、シェル起動時に取得する。

Home Managerはモジュールのpkgsを使い、inputsや構成選択はextraSpecialArgsで渡す。
NixOS組込ではuseGlobalPkgsを使う。importsの条件は構成引数から判断し、
configやpkgsの遅延評価に依存させない。

## ホストと機能

- nixos/hosts/nixos/: AMD機の生成済みhardware-configuration、ディスクUUID、起動・機器設定。
- nixos/hosts/macbook-air/: Intel MacBookの生成済み設定、起動・入力機器・ビルド並列数。
- nixos/hosts/nixos-wsl/: WSLのユーザー・SSH設定。
- nixos/system/: 共通のNix管理、OSサービス、実機サービス、デスクトップ機能。
- home-manager/hosts/: モニター配置など、Home Managerに属するホスト固有設定。
- home-manager/profiles/: base、gui-apps、hyprland、gaming等の用途別imports。
- home-manager/desktop/hyprland/: セッション、関連パッケージ、Waybar、入力切替。
- home-manager/programs/、packages/、shell/: 個別プログラム、導入一覧、シェル連携。
- home-manager/linux/obs/: OBSと録画用コマンドの連携。

新ホストのUUID・起動設定を既存ホストから流用しない。system.stateVersionは
各ホストの初回導入時の値を維持する。ディスク設定を移動するときも値は変更しない。

DP-2 / HDMI-A-2の固定配置はAMDホストのモジュールだけで設定する。
MacBookと単体Home ManagerではHyprlandの既定のモニター検出を使い、
固定配置が必要になった場合は各ホストに追加する。これは今回の配置整理に伴う明示的な変更。

## 設定ファイルの管理担当

| 対象 | 管理担当 | 方針 |
| --- | --- | --- |
| Boot・ディスク・ネットワーク・PipeWire・OS側IME | NixOS | OSのモジュールで宣言 |
| macOSのシステム設定・Homebrew | nix-darwin | OS側の設定を宣言 |
| HyprlandのLua設定・Waybar・hypridle・hyprlock・hyprpaper | Home Manager | パッケージパスやサービスと接続して生成 |
| Neovim・シェルのパッケージ連携 | Home Manager | Nixvimと対応するprogramsモジュール |
| Waypaperの静的config.ini・Ghostty・SwayNC等の利用者設定 | chezmoi | Home Managerで同じファイルを生成しない |
| OBSのGUIで変更するプロファイル・シーン等 | OBS、必要なファイルをchezmoiで取り込み | Home Managerは本体・プラグイン・制御コマンド・キー連携 |
| Minecraftのバージョン・Java・MOD資産・初期設定 | Minecraft用モジュール | 固定した定義と資産を使う |
| Minecraftのsaves・認証情報・実行中に変わる設定 | 通常のデータ領域 | 不足分の初期配置のみ。再適用で既存内容を上書きしない |

まずhome.packagesによる導入を検討し、必要ならサービス・programs設定を使う。
設定を生成する担当を変える場合は、chezmoi側の既存管理対象との競合も確認する。
機能専用の補助プログラムは機能の近くに置き、複数用途のパッケージだけpkgs/へ移す。

## Minecraft用flake

flakes/minecraft/は独立したinputs・lock・モジュール・docs・永続化テストを持つ。
親はgaming profileからhomeModules.defaultを読み込み、nixpkgsとHome Managerを共有する。
Vanilla、1.7.10の二環境、1.20.1をすべて移管し、バージョンとデータ保持処理は維持する。

## 検証

構造変更前後でパッケージ・サービス・生成設定を比較する。出力構造の評価、
影響パッケージのビルド、対象システムのビルドの順で確認する。
switchと実機動作は別の確認として記録する。
