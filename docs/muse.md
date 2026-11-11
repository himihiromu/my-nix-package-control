# Meta Muse の Linux 導入と Mac 版との比較

確認日: 2026-11-08

## Linux 版の調査結果

対象は [Meta の個人向けエージェント Muse](https://ai.meta.com/muse/)。
[公式ダウンロード案内](https://ai.meta.com/muse/download/)では Mac・iPhone・Android 向けを確認したが、
Linux 向けの公式アプリ配布や提供予定は確認できなかった。
固定した nixpkgs にも、この製品のパッケージは見つからなかった。
これは将来の提供を否定するものではなく、確認日時点の調査結果。

[公式 Web 版](https://muse.ai/)にはブラウザからアクセスでき、ログイン画面の表示を確認した。
Linux では、この Web 版へのランチャーを Home Manager で管理する。
公式に説明される「Linux computer / Muse Secure VM」はクラウド側の実行環境であり、
手元の Linux にインストールするデスクトップアプリとは別のもの。

`muse` コマンドを提供する [Muse Code](https://dev.meta.ai/docs/muse-code) は開発者向けの別製品。
今回の導入対象には含めない。同名の音楽アプリ等も対象外。

## Web 版と Mac 版

| 項目 | Linux で利用する Web 版 | Mac アプリ |
| --- | --- | --- |
| 起動 | `muse-web` またはメニューの「Muse (Web)」から既定ブラウザで開く | 公式 Mac アプリをインストールして起動 |
| 対話・タスク依頼 | ログインしてサービスを利用。アカウント内での実動作は未検証 | 同じ Muse サービスの専用クライアント |
| クラウド上のブラウザ・継続タスク | Muse 共通機能として案内。Web 固有の対応範囲は未検証 | Muse 共通機能として案内。Mac での実動作は未検証 |
| 外部サービス連携 | サービス側の Connectors に依存。ログイン後の利用可否は未検証 | 同様に連携先・許可に依存 |
| 手元のファイル・アプリ・ブラウザタブ | 今回のランチャーはローカル操作機能を追加しない。アップロード等の対応範囲は未検証 | 公式紹介でデスクトップのファイル・アプリ・ブラウザタブとの連携を案内 |
| Messages・Calendar・Notes | Mac のアプリ連携に相当する機能は、このランチャーにはない | 公式ダウンロード案内で、許可した範囲での連携を案内 |
| 通知・音声・ショートカット等 | ブラウザや権限にも依存。Mac 版との同等性は未確認 | 個別機能・必要な OS バージョン・CPU 要件は今回未確認 |

共通機能の根拠は [Muse の設計紹介](https://muse.ai/blog/how-we-designed-muse)。
Web と Mac の全機能が同一という意味ではない。
Mac 固有の説明は [製品紹介](https://ai.meta.com/muse/)と
[ダウンロード案内](https://ai.meta.com/muse/download/)に基づく。
[2026-09 の公式発表](https://about.fb.com/news/2026/09/introducing-muse-personal-ai-agent/)
では米国からの展開を案内している。ログインページへ到達できることだけでは、
日本のアカウントでの利用可否は判断できない。
認証後の機能、現在の利用地域・アカウント条件、実機の Mac での動作は未検証。

## Home Manager での管理

`home-manager/install-package/muse-web.nix` が次を生成する。

- `bin/muse-web`: Nix で解決した `xdg-open` で `https://muse.ai/` を開く。
- `share/applications/muse-web.desktop`: 上記実行ファイルを絶対パスで参照するメニュー項目。

`common.nix` から Linux の Home Manager 構成へ追加する。
`isDesktop = false` の WSL / Ubuntu でもコマンドを利用できる。
macOS のパッケージ一覧には追加しない。
ランチャーのコードと依存は Nix で固定するが、Web サービス自体の版は固定しない。

既存の対象ホスト用 Home Manager 構成をビルド・適用した後、次を実行する。

```sh
muse-web
```

既定ブラウザまたは `BROWSER` の設定が必要。
WSL で GUI メニューが公開されるかは Windows / WSL 側の構成による。
ブラウザでログインし、必要な接続先を選ぶ。認証情報は Nix ファイルへ保存しない。
Mac アプリのローカル連携が必要なら、Mac 側で公式アプリを導入する。

## 導入時の確認

2026-11-08、WSL2 上の Ubuntu / x86_64-linux で次を確認した。

- ランチャー単体の Nix ビルド（シェル検査・desktop entry の生成を含む）。
- 現在利用中の設定に追加した Home Manager 構成のビルド・適用。
- 適用前との差分は Muse ランチャーと関連する補完・manpath に限られること。
- 適用後の PATH から `muse-web` を実行し、既存の `BROWSER` 設定経由で
  Orca のブラウザに `https://muse.ai/` が読み込まれること。
- `isDesktop = false` の Linux では追加され、Darwin では追加されない条件の評価。

ログイン・アカウント作成・外部サービスへの接続は行っていない。
WSL から Windows のスタートメニューに表示されるかは未確認。
