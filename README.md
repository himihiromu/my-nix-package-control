個人用Nixパッケージ管理リポジトリ

NixOS + Home Manager + nix-darwin + chezmoi で Linux/macOS 環境を管理する。

## 対象構成

| 構成名 | 対象 | flakeの指定 |
|--------|------|----------------|
| nixos | AMDデスクトップ（実機） | `.#nixos` |
| macbook-air | Intel MacBookAir7,2（実機） | `.#macbook-air` |
| nixos-wsl | WSL2 on Windows | `.#nixos-wsl` |
| mac-config | macOS（nix-darwin） | `.#mac-config` |
| myHomeConfig | Home Manager 単体 | `.#myHomeConfig` |

## NixOS（実機）

```shell
# ホスト構成の適用（初回 / 設定変更時）
$ sudo nixos-rebuild switch --flake .#nixos

# テスト（再起動せずに試す）
$ sudo nixos-rebuild test --flake .#nixos

# ビルドのみ（適用しない）
$ nixos-rebuild build --flake .#nixos
```

新しいホストを追加するときは、その実機で生成した `hardware-configuration.nix` を
`nixos/hosts/<ホスト名>/` に配置する。既存ホストのファイルは上書きしない。
`isDesktop` は `user-options/options.nix` でホストごとに bool 値を切り替える。

## NixOS (WSL2)

```shell
# WSL内で適用
$ sudo nixos-rebuild switch --flake .#nixos-wsl
```

WSLでも共通のユーザー設定、Nix管理（flakes・信頼ユーザー・GC・最適化）、
Docker（rootful / rootless）、SSH、Home ManagerのCLIパッケージとシェル連携を適用する。
`wsl.defaultUser` は `local-options.username` に合わせる。

ユーザー名は明示したローカル設定を指定する（`username` と `isDesktop` を含むNix属性セット）。
既存のWSLユーザー名と合わせること。

```shell
sudo nixos-rebuild switch --flake "path:$PWD#nixos-wsl" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix"
```

WSLではAvahi、OS側のHyprlandセッション、音声、PolicyKit、日本語環境の追加設定を読み込まない。
GUIアプリやHome ManagerのGUI設定は、dotfilesで入力する `isDesktop` で選択する。
`false` ならCLI環境とZedリモートサーバー、`true` ならGUIアプリ（Zed・Bruno等）も追加する。
WSLでGUIアプリを選択した場合の表示には、WSLgなどホスト側のGUI機能が必要。
GUI常駐サービスとHyprlandセッションの設定は、`isWsl` によりWSLでは読み込まない。
NetworkManager、時刻同期、ファームウェア更新、Bluetooth・マウス管理、
ブート・ディスク・GPUなどの実機設定も読み込まず、WSL側の仕組みを使う。
ファイアウォールの共通設定は読み込むが、NixOS-WSLがゲスト内のファイアウォールを無効にする。
Windows側のネットワーク制御は別途管理する。

共通設定は `nixos/configuration.nix` と `nixos/system/{nix,services}.nix`、
実機用のサービスは `nixos/system/physical-services.nix`、
GUI・音声・権限・日本語環境は `nixos/system/desktop.nix` に分ける。
`isWsl` は `#nixos-wsl` のホスト定義でtrueにするWSL専用フラグ（他ホストはfalse）。
WSL固有のOS設定とGUIセッション除外に使い、NixOSとHome Managerへ渡す。
`isDesktop` はdotfilesから渡す、WSL・実機・Home Manager単体で共通のGUIアプリ選択フラグ。
`isDesktop` によって適用先ホストやNixコマンドは切り替えない。
実機では `true` のときにOS側のデスクトップ・音声・日本語環境も有効にする。
`false` はノートPCという意味ではなく、GUI環境を管理しないという意味で使う。

既存のdotfilesは対話入力を `~/.config/nix/local-input/default.nix` に出力し、
`mise nixos` 等で `--override-input local-options` として渡す。
WSLでは `mise nixos switch nixos-wsl` で構成を明示する。
dotfilesの初回導入スクリプトはNixOSの場合 `#nixos` を選ぶため、WSLの自動選択には別途修正が必要。

## nix-darwin (macOS)

```shell
$ sudo nix run nix-darwin -- switch --flake .#mac-config
```

## Home Manager（単体）

```shell
$ nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig --show-trace
```

## Claude Code（Z.ai）

リポジトリ内で以下を実行し、表示されるプロンプトに Z.ai の API キーを入力する（入力は非表示）。

```shell
nix develop
# 明示的に指定する場合: nix develop .#zai
claude
```

[Z.ai の公式手順](https://docs.z.ai/devpack/tool/claude)に従い、
`https://api.z.ai/api/anthropic` を利用する。Z.ai の API キーと利用可能な Coding Plan が必要。
Claude Code 本体も Nix で用意するため、別途 npm でインストールする必要はない。

事前に環境変数でキーを渡す場合（Bash）:

```bash
read -r -s -p 'Z.ai API key: ' ZAI_API_KEY; printf '\n'
export ZAI_API_KEY
nix develop .#zai
claude
```

キーはシェル起動時に `ANTHROPIC_AUTH_TOKEN` に設定する。
API キーを Nix ファイルに記載する必要はなく、Nix store にも埋め込まない。
`nix develop .#zai --command claude` のような非対話実行では、事前に `ZAI_API_KEY` を設定する。

モデルは既定で `glm-5.3-flash`。契約で利用可能な別モデルを使う場合は、
`ZAI_MODEL=モデル名 nix develop .#zai` で変更できる。
Opus / Sonnet / Haiku とサブエージェントにも同じモデルを設定する。

設定・認証・履歴は `${XDG_CONFIG_HOME:-$HOME/.config}/claude-zai` に保存する。
初回は Claude Code の初期設定が表示される場合がある。
起動後の `/status` で接続先とモデルを確認できる。
シェルを `exit` すると、親シェルの環境に戻る。

別のプロジェクトから使う場合:

```shell
nix develop /path/to/my-nix-package-control#zai
claude
```

## nixの容量削減

```shell
$ nix-store --gc
```

## ホストの選択

実機向けのNixOS構成は、flakeの `#` 以降に指定する名前で選択する。

| 構成名 | ハードウェア | 起動パーティション構成 |
| --- | --- | --- |
| `nixos` | 既存のAMDデスクトップ | ESPは `/efi`、XBOOTLDRは `/boot` |
| `macbook-air` | Intel MacBookAir7,2 | ESPは `/boot`、XBOOTLDRなし |

共通のシステム設定とHome Managerの連携設定は `nixos/configuration.nix` に置く。
ホスト固有のモジュール、ディスクUUID、起動設定、`system.stateVersion` は
`nixos/hosts/<ホスト名>/default.nix` とそこから読み込むモジュールで管理する。
MacBookの構成では、実機のBtrfsサブボリューム（`@root`、`@home`、`@nix`）、
JISキーボード、ハードウェア設定、ビルド並列数の制限を維持する。

このMacBookでは、かな・英数キーがXKBキーコード130・131として届く
（Fcitxでは `Hangul`・`Hangul_Hanja`）。ホスト設定でそれぞれをIMEの有効化・無効化に
割り当て、かなキーを繰り返し押しても日本語入力が有効なままになるようにする。
Fcitx側の既定の切替動作も、このキーの用途に合わせて上書きする。
GhosttyはWayland標準の入力機能を使うため、ラッパーで `GTK_IM_MODULE` を解除する。
端末、デスクトップ、D-Busからの起動で同じラッパーを使う。
キー割り当てを永続化するにはホスト設定を適用する。
一時的な `hyprctl keyword bind` による設定は、セッション再起動後には残らない。

適用前に、このリポジトリ内で構成を評価する。

```sh
nix eval "path:$PWD#nixosConfigurations.macbook-air.config.system.build.toplevel.drvPath" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix" --raw
```

次の適用コマンドは、対象のMacBook上でのみ実行する。

```sh
sudo nixos-rebuild switch --flake "path:$PWD#macbook-air" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix"
```

別のPCを追加する場合は、`nixos/hosts/` にそのPCのハードウェア・起動設定を追加し、
`flake.nix` の `mkNixos` で登録する。別の実機のディスクUUIDを流用したり、
既存ホストの `system.stateVersion` を変更したりしない。

### ノートPCのバッテリー表示とMacBookのトラックパッド

Waybarは内蔵バッテリーを自動検出し、右端に残量を％で表示する。
MacBookを含むノートPCで利用でき、バッテリーのないデスクトップPCでは表示しない。
充電中は充電アイコンに切り替わる。
設定は `home-manager/linux/waybar.nix` の `battery` にある。

MacBookのトラックパッドのカーソル速度は、`nixos/hosts/macbook-air/default.nix` の `settings.device` 内にある
`bcm5974` の `sensitivity` で調整する。現在は標準速度の `0.0`。
`0.2` などの正の値で速く、`-0.2` などの負の値で遅くなる（範囲は `-1.0`〜`1.0`）。
この設定は内蔵トラックパッドにだけ適用する。
スクロールは `scroll_factor = 0.7` で移動量を標準の70%に抑える。
値を小さくすると遅くなり、`1.0` に戻すと標準の移動量になる。

一時的に速度を試す場合は、Hyprlandのセッション内で次を実行する。

```sh
hyprctl keyword 'device[bcm5974]:sensitivity' 0.0
hyprctl keyword 'device[bcm5974]:scroll_factor' 0.7
```

好みの値が決まったらNix定義に記入し、上記のホスト構成の適用コマンドで永続化する。

MacBookでは、2本指で押し込むクリックと2本指タップを右クリックに割り当てる。
3本指の左右スワイプでワークスペース（仮想デスクトップ）を切り替える。
クリック設定は `settings.device`、スワイプ設定は `settings.gesture` にある。
3本指の上スワイプでは、[HyprExpo](https://github.com/sandwichfarm/hyprexpo)で
ワークスペースを縮小した一覧を開く。3本指の下スワイプまたはEscで閉じる。
プレビューをクリックすると、そのワークスペースへ移動する。
macOSのMission Controlに近い用途だが、表示はワークスペース単位のグリッドになる。

HyprExpoは `nixos/hosts/macbook-air/hyprexpo.nix` で対応版を固定し、
ホストと同じHyprlandの依存関係でビルドする。Hyprland更新時にはプラグインの互換性も確認する。

### MacBookの機能キー

上段のキーを単独で押すと、キーに描かれた明るさ・音量の操作になる。
通常のF1〜F12として使う場合はFnを押しながら操作する。

| キー | 操作 |
| --- | --- |
| F1 / F2 | 画面を暗くする / 明るくする（5%刻み） |
| F5 / F6 | キーボード照明を暗くする / 明るくする（10%刻み、消灯可） |
| F10 | 音声のミュートを切り替える |
| F11 / F12 | 音量を下げる / 上げる（5%刻み、最大100%） |

明るさと音量は長押しでも調整でき、画面ロック中も操作できる。
画面輝度は完全消灯を避けるため最小値を1に制限する。
キー割り当てはHyprland設定、Fnの動作は `macbook-hardware.nix` の `hid_apple fnmode=1` で管理する。

### Scrollingレイアウト

MacBookではHyprland標準の `scrolling` レイアウトを使用する。
ウィンドウを画面内に詰め込むのではなく、横方向に伸びる列へ並べ、フォーカスした列を表示範囲へ移動する。
列が1つだけの場合は画面いっぱいに広がり、複数ある場合は隣の列が一部見える。

| キー | 操作 |
| --- | --- |
| Super + H / L | 左／右の列へフォーカス移動 |
| Super + Shift + H / L | 現在の列を左／右の列と入れ替え |
| Super + , / . | 列幅をプリセットで縮小／拡大（1/3、1/2、2/3、全幅） |
| Super + P | 現在のウィンドウを独立した列へ移動 |
| Super + Shift + P | 現在のウィンドウを専用列から取り出す |
| Super + Ctrl + P | 前の列へウィンドウを統合、または独立列化 |
| Super + I | 現在の列を表示範囲に合わせる |

3本指左右スワイプはワークスペース切替、上下スワイプはHyprExpoの一覧表示の開閉に割り当てている。
Scrollingレイアウトの詳細は[Hyprland公式ドキュメント](https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/)を参照。

## Bash の略語展開

`flake.nix` の `localPackagesOverlay` が [bash-abbrev-alias](https://github.com/momo-lab/bash-abbrev-alias)
の固定コミットとハッシュから `pkgs.bash-abbrev-alias` を定義する。
`home-manager/install-package/common.nix` で他のパッケージと同様にインストールし、
`home-manager/shell/bash.nix` がパッケージ内のライブラリを参照して、`$XDG_CONFIG_HOME/bash/abbrev-alias.plugin.bash`
（既定では `~/.config/bash/abbrev-alias.plugin.bash`）を配置する。
[dotfiles PR #16](https://github.com/himihiromu/dotfiles/pull/16) の `.bashrc` が Nix 管理の対話 Bash の
Emacs モードで読み込み、`la`・`ll`・`lal` を登録する。
NixOS/Home Manager の通常の適用と、対応する chezmoi 設定の適用が必要。
`.bashrc` の管理は引き続き chezmoi が担当する。
ライブラリ未配置の場合も既存 alias は利用できる。

## ChatGPT Linux アプリ

Linux のパッケージ一覧に公式 Debian x64 配布物を NixOS 向けに調整した `chatgpt` を含める。
パッケージ定義は `home-manager/linux/chatgpt.nix`。
更新される `latest` URL は使わず、公式リポジトリ内のバージョン付き URL と SHA-256 を固定する。
更新時は `version` と `src.hash` を変更し、再ビルドと起動確認を行う。

通常の NixOS / Home Manager 適用後、アプリケーションメニューの ChatGPT または
`chatgpt` コマンドで起動する。ランチャーに `--ozone-platform=x11` を設定しているため、
Hyprland では XWayland を使う。既存の Hyprland 設定で XWayland は有効。
ネイティブ Wayland は今回の対象にしない。

確認時は、まず `chatgpt --version` が `26.1013.40934` と表示されることを確認し、
続いて起動・ブラウザ経由のログイン・日本語入力と変換・チャット送信を確認する。
既に別バージョンの ChatGPT が起動中なら、終了してから確認する。

2026-10-18 に固定配布物のハッシュ検証、パッケージビルド、バージョン表示、
一時 HOME と仮想 X サーバーでのウィンドウ生成を確認した（仮想環境の検証では `--disable-gpu` を追加）。
Home Manager の activation derivation 評価、インストール対象、Hyprland の XWayland 有効化も確認した。
実環境への適用、実際の XWayland / GPU、ログイン、日本語入力、チャット送信は未確認。

NixOS は公式サポート対象外であり、公式のネイティブ Wayland 対応も実験段階。
対応範囲の出典: [公式 Linux アプリガイド](https://learn.chatgpt.com/docs/linux/linux-app)（確認日: 2026-10-18）。

## Mozc と SKK の切り替え

Hyprland では **Super+Space** で Mozc と SKK を切り替える。
英数入力中に押すと Mozc を選択する。日本語入力のオン・オフは従来の
Ctrl+Space や、MacBook のかな・英数キーを使う。
Vicinae ランチャーは **Alt+Space** で起動する。

`home-manager/linux/toggle-japanese-input.nix` のコマンドを Hyprland のキーに登録する。
Mozc / SKK の両方が利用可能で、現在の入力メソッドグループに登録済みの場合だけ切り替える。
どちらかが不足していればエラー終了し、選択中の入力メソッドやグループの設定を変えない。
このコマンドはインストール・自動登録を行わない。
インストールは既存の `nixos/system/desktop.nix` の定義を使う。
グループへの登録は別途必要で、インストール済みというだけでは切り替え対象にならない。

NixOS / Home Manager の設定を適用して Hyprland を再読み込みした後、
文字入力欄で Super+Space を押して切り替えを確認する。
切り替わらない場合は `fcitx5-remote -n` で選択中の入力メソッド名を確認できる。

検証は `tests/test_japanese_input.py` で専用の D-Bus / Fcitx5 と一時 HOME を作成して行う。
Python の `dbus-next` と、次の実行ファイルを環境変数で指定する。

- `FCITX5_TEST_BIN`: Mozc・SKK を含む `config.i18n.inputMethod.package` の `bin/fcitx5`
- `FCITX5_WITHOUT_SKK_TEST_BIN`: addons から `fcitx5-skk` を外した同パッケージの `bin/fcitx5`
- `FCITX5_WITHOUT_MOZC_TEST_BIN`: addons から `fcitx5-mozc` を外した同パッケージの `bin/fcitx5`
- `TOGGLE_JAPANESE_INPUT_BIN`: `toggle-japanese-input.nix` をビルドした `bin/toggle-japanese-input`
- `DBUS_DAEMON_TEST_BIN`: Nixpkgs の `dbus` の `bin/dbus-daemon`

`python3 tests/test_japanese_input.py -v` で登録済みエンジンの切り替え、英数入力からの選択、
既存グループ・配列の保持、各エンジンの未登録・未インストール時に切り替えも設定変更もしないことを確認する。
