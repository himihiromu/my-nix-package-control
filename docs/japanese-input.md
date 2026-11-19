# SKKの入力異常の調査

確認日: 2026-11-20。ユーザーから「変な文字が入り、クリックするまで入力を続けられないことがある」と報告を受け、Nix定義・稼働設定・既存ログ・隔離したFcitx5を確認した。発生アプリ、文字の具体例、発生時刻は未確認。

## 確認できたこと

- 稼働環境はHyprland 0.57.1 / Wayland、Fcitx5 5.1.23、fcitx5-skk 5.1.11 / libskk 1.1.0。SKKとMozcが登録済みで、採取時の選択はSKK。
- Fcitx5はUWSMの `app-org.fcitx.Fcitx5@autostart.service` で1プロセス稼働。`fcitx5.service` がないこと自体は異常ではない。
- 11月13日の起動から11月20日の採取までの当該プロセスのjournalには、SKKのロード成功と定期保存があり、エラーや再起動は見つからなかった。キー・文字・フォーカス遷移の履歴はない。現在残っているOrcaの `main.trace.ndjson*` と `daemon.log` にもIMEに該当する記録は見つからなかった。入力内容を過去にさかのぼって再現できるログは確認できていない。
- SKKの有効設定は `Rule=default`、`InitialInputMode=Hiragana`、`EggLikeNewLine=False`。ユーザーの `conf/skk.conf` は存在せず、標準のシステム辞書とユーザー辞書の定義がある。ユーザー辞書の本文は調査対象にしていない。
- Hyprlandの `input:kb_layout=jp` に対し、Fcitx5のグループは `Default Layout=us` / `keyboard-us`。現在のHyprlandの各キーボードのactive keymapはJapanese。差異だけでは原因と断定できないため、profileは変更していない。
- Hyprlandの `input:follow_mouse=1`。マウス移動でフォーカスが変わる可能性があるが、症状発生時の記録がなく因果関係は未確認。
- Orca 1.4.224 / Electron 43.7.5はネイティブWaylandで動作し、Fcitx5に `program:orca frontend:wayland_v2` の接続がある。採取時の `focus:0` はその瞬間の状態で、障害の証拠ではない。`wayland_v2` はFcitx側の入力メソッドfrontend名で、アプリ側のtext-inputプロトコルの版を示さない。

## 再現できたEnterの問題と変更

一時HOME・専用D-Bus・実Fcitx5を使い、普段の入力環境から分離して `Kanji` → Space → Enter → `a` → Enterを入力した。

| SKK設定 | 変換確定のEnter | 確定文字と後続入力 | 通常のEnter |
| --- | --- | --- | --- |
| `EggLikeNewLine=False`（稼働時の値） | アプリへ渡る | `漢字`、`あ` | アプリへ渡る |
| `EggLikeNewLine=True` | SKKが消費する | `漢字`、`あ` | アプリへ渡る |

現在の設定では変換確定時のEnterで、アプリの送信・改行などが同時に動作し得る。これを避けるため、`nixos/system/desktop.nix` に次を追加した。

```nix
i18n.inputMethod.fcitx5.settings.addons.skk.globalSection.EggLikeNewLine = true;
```

`tests/test_japanese_input.py` の2件で変更前後を検証した。NixOSの `nixos` / `macbook-air` 両構成を評価し、生成される `/etc/xdg/fcitx5/conf/skk.conf` が `EggLikeNewLine=True` になることも確認した。実アプリの送信・フォーカス喪失と同じ事象を再現したわけではなく、報告された症状の根本原因は未確定。

システムへの適用・稼働Fcitx5の再設定はこの調査では行っていない。通常のNix適用後、変換中でない状態でFcitx5を再起動するか次回ログイン時に読み込ませる。ユーザーの `~/.config/fcitx5/conf/skk.conf` が後から作られるとシステム設定より優先されるため、最終的な有効値を確認する。

```sh
busctl --user --json=short call org.fcitx.Fcitx5 /controller \
  org.fcitx.Fcitx.Controller1 GetConfig s fcitx://config/addon/skk \
  | jq '.data[0].data.EggLikeNewLine'
```

## 残る候補と切り分け

| 条件・症状 | 確認すること |
| --- | --- |
| Enterの直後に止まる・送信される | 上記変更後に比較する。変換確定にCtrl+jを使う場合も比較する。 |
| カタカナ・全角英数になる | 標準SKKには `q` / `l` / `L` によるモード変更がある。発生した文字と直前のキーを記録する。 |
| 記号だけ意図と違う | `jp` / `us` の差異を調べる。英数時・SKK時、Wayland・XWaylandのアプリで同じ物理キーを比較する。 |
| クリックすると復帰する | アプリの入力欄フォーカス、Hyprlandのactive window、Fcitx5のIC focusの対応を見る。ウィンドウがactiveでも入力欄がfocusedとは限らない。 |
| Orca内だけで文字・Space・数字が混入する | Orcaの端末・チャット入力欄・内蔵ブラウザのどこかを区別し、Ghosttyや外部ブラウザと比較する。 |

Orcaには、1.4.224の端末でIME候補選択のSpace・数字が混入する報告 [#28213](https://github.com/stablyai/orca/issues/28213) があり、後続修正 [#28275](https://github.com/stablyai/orca/pull/28275) で閉じられている。ただし報告環境はX11 / fcitx4 / Sogouで、今回のWayland / SKKと同一原因とは確認できていない。更新の有力な比較材料だが、本調査ではOrcaの版・起動方式を変更していない。

## 再発時の状態を採る

以下を端末で開始し、元のアプリへ戻って操作する。約2分、1秒ごとに状態を採取する。異常が出た時刻と、クリックして復帰した時刻を控えれば、その前後を比較できる。入力文字・クリップボード・ウィンドウタイトルは収集しない。Fcitx5のDebugInfoには接続アプリ名・入力コンテキストIDとfocus状態が含まれる。

```sh
(
  umask 077
  log=$(mktemp /tmp/japanese-input-state.XXXXXX.log)
  printf '保存先: %s\n' "$log"
  for _ in $(seq 1 120); do
    {
      date --iso-8601=seconds
      timeout 2s fcitx5-remote
      timeout 2s fcitx5-remote -n
      timeout 2s hyprctl -j activewindow | jq '{address, class, pid, xwayland}'
      timeout 2s busctl --user --json=short call org.fcitx.Fcitx5 /controller \
        org.fcitx.Fcitx.Controller1 DebugInfo | jq -r '.data[0]'
    } >> "$log" 2>&1
    sleep 1
  done
)
```

`focus:0` の単独採取や通常時の比較だけでは原因確定できない。異常時にもSKK以外の英数入力まで止まるか、Ctrl+gで変換を取り消すと復帰するかも確認する。

## 出典

- 2026-11-20のユーザー報告、ローカルのNix定義・設定ファイル・D-Bus GetConfig / DebugInfo、Hyprland状態、user journal、Orcaログの該当語検索。
- [fcitx5-skk 5.1.11の設定定義](https://github.com/fcitx/fcitx5-skk/blob/5.1.11/src/skk.h): `EggLikeNewLine` の既定値と説明。
- [Fcitx公式Wayland設定](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland): アプリ別の入力経路。GTK_IM_MODULE未設定だけを異常とは扱わない。
- ローカルのlibskk 1.1.0 `share/libskk/rules/default/keymap/{default,hiragana}.json`: モード切替・確定・取消キー。
