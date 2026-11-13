# Hyprlandでゲームウィンドウだけを録画する

確認日: 2026-11-13。対象は物理LinuxデスクトップのHome Manager設定。
NixOS/Home Managerのswitch、OBS設定変更、chezmoi applyは実行していない。

## 管理境界と導入

- Nix: `home-manager/linux/obs/default.nix` がOBSと `obs-pipewire-audio-capture` を導入。
  `obs/control.nix` / `obs/control.py` がPython + websockets + libnotifyの操作コマンドを提供する。
  常駐クライアントは追加しない。
- chezmoi: GUI生成後の録画プロファイル、録画エンコーダー、シーン、保存先、リプレイ設定。
  OBS設定をHome Managerの `xdg.configFile` / シンボリックリンクで配置しない。
- ローカル専用: `plugin_config/` 全体（特に `obs-websocket/config.json`）、
  配信サービス認証、`user.ini` のUI配置・選択状態、Portal復元トークン、音声デバイス固有ID。

既存の `nixos/system/desktop.nix` はHyprland/UWSM、PipeWire、Polkitを有効化済み。
固定nixpkgsのHyprlandモジュールがHyprland/GTK Portalを登録し、WirePlumberは既定で有効。
`nixos/system/hardware.nix` の `hardware.graphics.enable` によりMesa/radeonsi VAAPIが供給される。
AMD用の別ドライバや `obs-vaapi` を追加しない。

現在のlock: nixpkgs `3ec636362e1816bc2f0888fa0fa2c69f1bc9e504`。
OBS **32.2.2**、音声プラグイン **1.2.2**。OBSのビルドはLinuxでPipeWire対応、
標準WebSocket搭載。FFmpeg VAAPI AV1はOBS本体に含まれる。
音声プラグインはOBS 32でアプリケーション単位の音声取得に必要なので追加する。

導入は既存READMEの環境別手順で、物理デスクトップ用local-options（`isDesktop = true`）を選び、
変更をレビューしてからユーザー自身が適用する。既定のlocal-optionsはdesktop=falseなので注意。
単体Home Managerで使う場合、OS側のPortal/PipeWire/VAAPIは別途必要。

## 初回GUI設定（必須）

既存 `無題` プロファイルには名前しかなく、シーンには映像ソースがない。
録画・エンコーダー設定は未生成のため、推測したINI/JSONは配布していない。
次の設定をOBSで保存し、終了してからdotfiles側手順で取り込む。

1. `Super+Shift+O` でOBSを起動する。自動構成ウィザードに依存せず、
   プロファイルを `GameRecording`、シーンコレクションを `GameRecording` として作る。
2. 設定 → 音声: **48 kHz、ステレオ**。グローバルのデスクトップ音声とマイクを全て無効化し、
   必要な音声だけシーンソースに追加する。他アプリの通知音・音声が混ざるのを避ける。
3. ゲームを起動し、ソースに **ウィンドウキャプチャ (PipeWire)** を追加する。
   OBS 32.2.2の `pipewire-window-capture-source` はPortalにウィンドウ型のみ要求する。
   Portal選択画面から対象ゲームだけを選ぶ。ソース候補にウィンドウキャプチャがない場合は
   Portalがウィンドウ共有を提示できているか調査し、録画を開始しない。
   モニター/領域キャプチャや画面を切り抜く方法を使わない。
   対象を閉じた後もモニター全体へ切り替わらないことを確認する。
   OBSのソース名だけでは選択対象を保証できないので、録画前にプレビューを確認する。
4. PipeWireのアプリケーション音声キャプチャソースで対象ゲームの音声を選ぶ。
   Protonでは実行名がゲーム名と異なる場合がある。別アプリで音を鳴らし混入しないか確認する。
   マイクは音声入力ソースとして追加する。既定デバイスか端末固有IDかを確認する。
   同じ音声をグローバルとシーンの両方から取得しない。
5. ソースの変形メニューの「ソースに合わせて出力サイズ変更」相当の操作でゲームの実寸を使う。
   設定 → 映像で基本/出力解像度を同じ値にし、**60 FPS** を選ぶ。
   OBSのキャンバスは固定サイズ。ゲームの解像度変更時は録画・リプレイを停止して再設定する。
   任意ウィンドウへの自動解像度追従は実装していない。
6. 設定 → 出力を詳細モードにして、録画形式 **Matroska (.mkv)**、
   保存先 **`~/Videos/Recordings` の絶対パス**（先に `mkdir -p ~/Videos/Recordings`）、
   エンコーダー **FFmpeg VAAPI AV1**、AMD GPUのVAAPIデバイスを選ぶ。
   録画の再スケーリングは無効。レート制御は **CQP、QP 20** を初期値にする。
   これはOBS 32.2.2の実装にある既定値・項目で、CRFやICQではない。
   実際の画質/負荷/容量を見てQPを調整する。QPが小さいほど高品質・大容量。
   GPUドライバが提示する項目を優先し、使えない制御方式は強制しない。
7. 同じ出力設定でリプレイバッファを有効化し、最大時間 **300秒**。
   メモリ上限が表示される場合、300秒を保持できる容量を設定する。
   例えば平均50 Mb/sなら映像だけで約1.88 GB/300秒。上限によって300秒より短くなり得る。
   詳細設定のファイル名を `Recording-%CCYY-%MM-%DD_%hh-%mm-%ss`、
   リプレイの接頭辞を `Replay-` にする（GUIで実際のファイル名を確認）。
   リプレイも録画と同じ保存先・エンコーダーを使う。
8. ツール → WebSocketサーバー設定: サーバー有効、**認証有効**、ポート **4455**。
   OBSでパスワードを生成する。コマンド引数、環境変数、Nix式にパスワードを渡さない。
   設定を保存してOBSを終了し、次を実行してから再起動する。

   ```sh
   chmod 700 ~/.config/obs-studio/plugin_config/obs-websocket
   chmod 600 ~/.config/obs-studio/plugin_config/obs-websocket/config.json
   ```

スクリプトはこのローカルJSONから実行時に設定を読み、保存済み設定と同じ認証を使う。
認証無効、所有者不一致、権限が広いファイル、ファイル自体のsymlinkは拒否する。
ポートをGUIで変更した場合も保存・再起動後に追従する。

OBS標準サーバーは全インターフェースで待ち受ける。localhost専用の待受設定は仮定しない。
クライアントはプロキシを使わず **127.0.0.1にのみ接続**し、既存NixOSファイアウォールは
4455を開放しない。`ss -ltnp` と別端末からの接続試験で外部アクセス不可を確認する。
独自のファイアウォール設定で4455を許可している環境には、その許可を持ち込まない。

AV1が候補にない/録画開始に失敗する場合、まずOBSログと一時的に使う `vainfo` で
AMDデバイスの `VAProfileAV1Profile0` のエンコードエントリを確認する。
`nix shell nixpkgs#libva-utils -c vainfo --display drm --device /dev/dri/renderD128` は診断例。
デバイス番号は固定しない。代替は **FFmpeg VAAPI H.264 + CQP/QP 20**。
これも利用不可ならx264を暫定使用し、CPU負荷を確認する。実機のAV1可否は未検証。

## 操作

| キー/コマンド | 操作 |
| --- | --- |
| Super+Shift+O | OBS起動（UWSM経由） |
| Super+Shift+F9 / `obs-control start` | 録画開始、既に録画中なら再開始しない |
| Super+Shift+F10 / `obs-control stop` | 録画停止 |
| Super+Shift+F11 / `obs-control replay` | 実行中のリプレイを保存要求 |
| `obs-control status` | 録画・リプレイ状態を通知 |
| `obs-control replay-start` / `replay-stop` | リプレイ開始・停止 |

既存キーとの競合なし。結果とエラーはnotify-sendからswayncへ通知する。
録画操作はOBSのフォーカスに依存しない。開始/停止はトグルではない。
リプレイは**手動開始**。ゲームと音声の選択を確認してから `obs-control replay-start` を使う。
起動直後から300秒分のメモリ/GPUを使うことや、意図しないシーンの保持を避けるため。
保存通知はOBSが保存要求を受理したことを示す。実際の出力ファイルも確認する。

## chezmoiへの取り込み・復元

[dotfiles側README](https://github.com/himihiromu/dotfiles/blob/main/docs/obs-recording.md) を参照。
実際のchezmoi既定sourceは `~/.local/share/chezmoi` であり、開発先dotfilesとは異なる。
作業対象を間違えないよう、手順では `chezmoi -S ~/ghq/github.com/himihiromu/dotfiles` を使う。
認証ファイルや `plugin_config/` を再帰的にaddしない。

## 実機受け入れ確認

- `systemctl --user status pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-hyprland`、
  `journalctl --user -b -u xdg-desktop-portal-hyprland` を確認。
  `systemctl --user show-environment` の `WAYLAND_DISPLAY` / `XDG_CURRENT_DESKTOP` が正しいこと。
- OBSのウィンドウキャプチャ (PipeWire) ソースでMinecraftのWayland/XWayland、Steamのネイティブ/Protonそれぞれを選択。
  別ウィンドウを重ねる、フォーカスを他アプリに移す、ワークスペースを切り替える、
  ゲームを閉じる、再起動する、全画面化する操作を行い、プレビューと保存動画を確認。
  他のウィンドウ/画面全体が映る場合は録画せず、ソースを削除して対象を選び直す。
- 録画中に別アプリ音声を鳴らし、ゲーム音声とマイクのみ録音されることを確認。
- OBS非アクティブでF9/F10、二重F9、停止中F11、OBS未起動時を試し通知を確認。
- リプレイ開始後300秒以上待ちF11。出力の長さ、音ズレ、保存先/名前を確認。
- `ffprobe` 等でMKV/AV1/60fps/48kHzを確認。統計画面でエンコード/描画遅延を確認。
- OBS終了後にchezmoiで取り込み、別環境に復元して通常ファイル・書込可能であることと、
  ソース再選択およびローカルWebSocket認証再設定を確認。

Portalのトークンやゲームの音声識別子は端末をまたいだ復元を保証しない。
ヘッドレス評価だけでゲームウィンドウ選択・AV1実エンコード・swaync表示の成功とは判定しない。

## 出典

- [固定nixpkgsのOBS](https://github.com/NixOS/nixpkgs/blob/3ec636362e1816bc2f0888fa0fa2c69f1bc9e504/pkgs/applications/video/obs-studio/default.nix)
- [OBS 32.2.2のウィンドウ専用PipeWireソース](https://github.com/obsproject/obs-studio/blob/32.2.2/plugins/linux-pipewire/screencast-portal.c)
- [OBS 32.2.2 VAAPI実装（CQP/QP既定値を含む）](https://github.com/obsproject/obs-studio/blob/32.2.2/plugins/obs-ffmpeg/obs-ffmpeg-vaapi.c)
- [obs-vaapi作者によるOBS本体エンコーダーの案内](https://github.com/fzwoch/obs-vaapi)
- [PipeWire音声プラグイン](https://github.com/dimtpap/obs-pipewire-audio-capture)
- [Hyprland画面共有](https://wiki.hypr.land/useful-utilities/screen-sharing/)
- [標準WebSocketプロトコル](https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md)
- [標準WebSocket待受実装](https://github.com/obsproject/obs-websocket/blob/master/src/websocketserver/WebSocketServer.cpp)

## 今回の変更と検証記録

Nix側の変更ファイル:

- `home-manager/linux/obs/default.nix`: Home ManagerのOBSモジュールと4キーバインド（Hyprlang/Lua対応）。
- `home-manager/linux/obs/control.nix` / `control.py`: 操作用パッケージと実装。
- `home-manager/linux/services.nix`: OBSモジュールのimport。
- `home-manager/linux/multimedia.nix`: 素のOBSをパッケージ一覧から除き、二重導入を避ける。
- `tests/test_obs_control.py`: WebSocket認証・状態遷移・失敗時の検証。
- `README.md` / `docs/obs-recording.md`: 案内・手順。

chezmoi側の変更ファイル:

- `dot_config/obs-studio/global.ini.tmpl`: 実際に生成済みの設定を通常ファイルへコピー。
- `.chezmoiignore` / `.gitignore`: 認証・実行時データの除外とGit許可リスト。
- `scripts/check-obs-config.py`: INI/JSONの既知の機密フィールド検査。
- `README.md` / `docs/obs-recording.md`: 初期設定後の取り込み・更新・復元手順。

実施結果:

- Nix構文、変更Nixファイルのnixfmtチェック: 成功。
- desktop=trueのNixOS/Home Manager評価、OBSと音声プラグインのdrv評価、
  Home Manager activationPackageのdrv評価: 成功。switchは実施していない。
- 生成Hyprland設定で4キーバインドと実行先を確認（Hyprlang/Lua両形式）。
- 操作パッケージのビルドと `--help` 実行: 成功。
- `tests/test_obs_control.py` の6テスト: 成功。
  実WebSocket接続でv5認証、開始・停止、二重開始抑止、停止中リプレイ拒否、
  認証設定権限、OBS未起動時の処理を検証した。サーバーはテスト用。
- 完成した操作スクリプト/ラッパーにローカルOBSの実パスワードがないことを値を表示せず確認。
  OBSの認証ファイルをNix式で読み込んでいない。
- 一時ホームへの対象限定chezmoi apply: 通常ファイル・書込可能・パス展開成功。
  plugin_configはコピーされず、desktop=falseではOBS設定を除外することを確認。
- 秘密フィールド・salt・Portal token・認証URLの拒否、Gitの秘密/backup除外を確認。
- PipeWire/WirePlumber/Hyprland+GTK Portal/graphics/Polkitは評価上すべて有効のまま。

未実施: OBS本体/プラグインの実機ロード、ゲーム個別選択、音声分離、AMD AV1録画、
300秒リプレイ、swaync実表示、別端末復元。録画用プロファイルとシーンの採取はGUI設定後に行う。
既存の他作業の未コミット変更を維持し、システム適用は行っていない。
