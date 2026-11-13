# Minecraft / Prism Launcher / Prismix

確認日: 2026-11-11。

## 構成

Minecraftの実装は `home-manager/install-package/minecraft/` にまとめる。

```text
minecraft/
├── default.nix          # Launcher・Vanillaと各環境の読み込み
├── legacy.nix           # 1.7.10の2環境
├── legacy-manifest.json # 旧MOD・初期設定のファイルとハッシュ
├── modern.nix           # 1.20.1環境
├── modern-lock.json     # 配布URL・バージョン・ハッシュ
└── assets.py            # 資産登録・照合・既存設定を保持した初期配置
```

固定JSONはNix定義と合わせて更新する構成情報なので、このリポジトリで管理する。
プレイ中に変わる `options.txt`、MOD設定、ワールド、認証情報はユーザーデータとして扱う。
これらを固定JSONと一緒にGitへ入れたり、適用のたびに初期状態へ戻したりしない。
dotfiles側へMODの固定情報を重複させない。

既存の `home-manager/default.nix` から、Linux かつ `isDesktop = true` の場合だけ
Prismix と `install-package/minecraft/default.nix` を import する。NixOS 経由・単体 Home Manager の両方で利用できる。
macOS と CLI 構成には追加しない。Linux Desktop の WSL では WSLg 等の GUI 環境が別途必要。

- Prismix: **v0.1.0**、`f9155d606cc28b299eb05ce316bb0ccadb8ae371`。
  input は `git+https://codeberg.org/OliMoli/prismix?ref=refs/tags/v0.1.0`。
  `inputs.nixpkgs.follows = "nixpkgs"` とし、既存の nixpkgs を共有する。
- import: `inputs.prismix.homeModules.default`（`homeManagerModules.default` と同じモジュール）。
  Home Manager 標準の `programs.prismlauncher` を拡張し、同モジュールが Launcher をインストールする。
  `home.packages` に重複追加しない。prismnix は使用していない。
- Prism Launcher: ロック済み nixpkgs の **11.1.1**。Java は `pkgs.jdk25`、`pkgs.jdk8`、`pkgs.jdk17` を Launcher に渡す。
- インスタンス名・ディレクトリ名: **Vanilla**。
  Minecraft **26.3**、Java **25**、最小 **1024 MiB**、最大 **4096 MiB**。
  MOD ローダー・MOD・シェーダー・リソースパックは追加しない。
- 旧MOD環境は `install-package/minecraft/legacy.nix` で以下の2つを追加する。

| インスタンスID | 表示名 | Minecraft / Forge | Java / メモリ |
| --- | --- | --- | --- |
| `Industrial-1.7.10-Trial` | Industrial 1.7.10 - Trial | 1.7.10 / 10.13.4.1614 | Java 8 / 1024–6144 MiB |
| `Industry-Magic-1.7.10-Trial` | Industry & Magic 1.7.10 - Trial | 1.7.10 / 10.13.4.1614 | Java 8 / 1024–6144 MiB |

新しい工業・魔術環境 **Industry & Magic 1.20.1** も追加している。
Minecraft 1.20.1 / Forge 47.4.28 / Java 17 / 1024–8192 MiB。
[1.20.1構成・固定ファイル・検証結果](minecraft-modern.md)を参照。

Vanilla の版は Mojang の公式 manifest の `latest.release` と、その版の `javaVersion.majorVersion`
を実装時に照合して固定した。評価・ビルド時に最新バージョンへ問い合わせる処理はない。
Prismix v0.1.0 の per-instance `config.java.path` は `OverrideJavaArgs` を生成するため、
`extraConfig.OverrideJavaLocation = true` を明示し、Prism Launcher の実装と合わせている。

## 初回適用とプレイ

**初回ビルドの前に、次節のローカルMOD資産を登録する。**
この変更の検証では switch / NixOS rebuild は行っていない。ゲームを終了してから適用する。
設定を適用する際は既存の手順に従う。NixOS の例:

```sh
mise nixos switch
```

`~/.config/nix/local-input/default.nix` の `isDesktop` は `true` とする。
同名インスタンスの競合がある場合は、後述の保護処理で変更前に停止する。

1. アプリ一覧の **Prism Launcher**、またはターミナルの `prismlauncher` で起動する。
2. 右上のアカウントメニューから「アカウントの管理」→「Microsoft を追加」を選ぶ。
   表示されるブラウザ/デバイスコード認証を完了する。Minecraft Java Edition の利用権があるアカウントを使う。
   パスワードやトークンを Nix ファイルや Git に記入しない。
3. 一覧の **Vanilla** をダブルクリックする。初回はゲーム本体とアセットのダウンロードにネット接続が必要。
   インスタンス編集画面で Minecraft 26.3、Java 25、メモリ 1024/4096 MiB を確認できる。
4. ゲームの「シングルプレイ」→「ワールド新規作成」で名前を入力し、
   **ゲームモード: サバイバル / 難易度: ノーマル** を選んで作成する。
5. 少しプレイして「セーブしてタイトルへ戻る」を選び、同じワールドを再度開いて保存を確認する。

Prismix は `options.txt` の設定を扱えるが、ワールドのゲームモード・難易度や `level.dat` を生成する API はない。
これらはワールド作成画面で指定する。実ゲームの起動、Microsoft 認証、ワールドの作成・再読み込みは手動確認が必要。

## 1.7.10のローカルMOD資産

ファイル定義は `home-manager/install-package/minecraft/legacy-manifest.json` に置く。
元の「工業MOD」「工業と魔術」のMOD本体、`mods/1.7.10/` のライブラリ、MODの初期設定、
`GregTech.cfg` / `GregTech.lang` をSHA-256で固定する。ミニマップの `.points`、
セーブ、バックアップ、ログ、Microsoft認証情報は含めない。
MODバイナリをGitへ格納したり、オンラインの最新版へ置き換えたりしない。

初回は元ディスクを `/mnt/minecraft` にマウントし、リポジトリのルートで実行する。

```sh
nix shell --inputs-from . nixpkgs#python3 -c python3 \
  home-manager/install-package/minecraft/assets.py cache \
  --manifest home-manager/install-package/minecraft/legacy-manifest.json
```

適用後は同じ処理を `minecraft-legacy-cache` で実行できる。
元ディスクの場所が異なる場合は `--source-root '/別の場所/マインクラフト　ファイル'` を付ける。
時刻・所有者・順序を固定したtar.gzを `~/.cache/minecraft-legacy/` に作成し、
アーカイブ自体のSHA-256も確認して `nix-store --add-fixed sha256` で登録する。
別のマシンでは、同じ元ファイルから作るか、この2つのアーカイブを移して登録する。

```sh
nix-store --add-fixed sha256 /保存先/Industrial-1.7.10-Trial-assets.tar.gz
nix-store --add-fixed sha256 /保存先/Industry-Magic-1.7.10-Trial-assets.tar.gz
```

Nixは `requireFile` で固定済みアーカイブを要求し、未登録ならビルドを停止する。
そのため、ディスクを評価時に参照する `--impure` や、マウントされていない場合の無条件スキップは不要。
アーカイブ内のMODには個別の利用条件があるため、`requireFile` のunfree許可はこの2ファイルの名前だけに限定する。

適用時の動作:

- 既存の今回作成した2インスタンスはMinecraft/Forgeの版・形式・MODハッシュを照合して取り込む。
  取り込み前の `instance.cfg` / `mmc-pack.json` は `.legacy-before-nix/` に保管する。
- MODや初期設定は不足分だけ通常ファイルとしてコピーする。既存の設定と `options.txt` は保持する。
  新しい環境の `options.txt` だけ、日本語・描画距離8チャンクで初期化する。
- 既存MODのハッシュ変更、追加のJAR/ZIP、対象パスのリンク、起動中の対象ゲームを検出したら変更前に停止する。
- `minecraft/saves` は作成するだけ。移行済みワールドをStoreへ取り込まず、再コピー・復旧・展開を繰り返さない。
  新しいマシンではワールドを別途コピーする。

この2環境は、Nix化前にそれぞれ80 / 103 MODの読み込み成功をログで確認した構成を基にしている。
Nix適用後の実ゲーム起動と移行ワールドのプレイは別途確認する。

## セーブデータと既存データの保護

標準の保存先:

```text
~/.local/share/PrismLauncher/
├── prismlauncher.cfg                 # 書き込み可能。管理項目のみマージ
├── accounts.json                    # GUI 管理。Nix から読み書きしない
└── instances/Vanilla/
    ├── .hm_instance.cfg             # Home Manager が Store にリンクする雛形
    ├── .hm_mmc-pack.json            # 同上
    ├── instance.cfg                 # 書き込み可能な通常ファイル
    ├── mmc-pack.json                 # 通常ファイル。版を Nix で固定
    └── minecraft/
        ├── options.txt              # GUI 管理
        └── saves/<ワールド名>/       # 書き込み可能な通常ディレクトリ
```

`xdg.dataHome` を変更した場合は、その下の `PrismLauncher` を使う。
ワールドの作成先は `instances/Vanilla/minecraft/saves`。Prism Launcher は `minecraft` がある場合にそこをゲームディレクトリとして使う。
Prismix は `.hm_*` の変更時に設定をマージ/コピーするだけで、`saves` は管理しない。
追加した activation も `mkdir -p` で saves を用意するだけで、削除・移動・上書きは行わない。
再適用・flake input の更新では saves を初期化しない。バックアップはゲーム終了後、ユーザーデータとして別途取得する。

保護処理は書き込み境界の前に次を検査する。

- 既存の Vanilla に Prismix の `.hm_instance.cfg` / `.hm_mmc-pack.json` リンクがなければ停止する。
- 対象ディレクトリがシンボリックリンク等であれば停止する。
- 更新対象の設定が通常ファイルでない場合や、旧形式の `.minecraft` がある場合も停止する。

**競合時:** 強制適用やディレクトリ削除は行わない。既存データをバックアップし、
このモジュールの属性名 `instances.Vanilla` と保護処理・saves 作成処理の `vanillaDir` を
未使用の同じ名前へ変更する方法を使う。既存インスタンスを取り込む場合は内容を個別確認する。
1.7.10の2環境については、上記の専用の照合処理で取り込む。
Prismix を設定から外してもワールドは残るが、`.hm_*` がなくなった後の再導入は既存データとして保護対象になる。

既存の Launcher 設定は保持しつつ、Prismix はグローバルの Java パスと自動 Java 選択/ダウンロード設定を管理する。
他のインスタンスがグローバル Java に依存している場合は、適切な Java をインスタンス別に指定する。
既存の全体設定で別の `InstanceDir` を指定している場合、本構成の標準保存先と一致するよう手動確認が必要。

## 管理範囲と更新

| Nix で管理 | GUI / ユーザーデータとして管理 |
| --- | --- |
| Launcher・Java パッケージ | Microsoft ログイン・認証情報 |
| インスタンス名・Minecraft の版 | ワールド名・シード・ゲームモード・難易度 |
| Java パス・メモリ・MOD 定義 | セーブ・スクリーンショット・ゲーム内設定 |

Minecraft を更新する場合は、ゲームを終了してワールドをバックアップし、公式のリリースと Java 要求を確認する。
`home-manager/install-package/minecraft/default.nix` の `minecraft.version` と必要なら Java を変更し、評価・ビルド後に通常の手順で適用する。
`nix flake update` だけでは Minecraft の明示した版は変わらない。新しい版で開いたワールドの古い版への戻しは避ける。
Prismix 自体を更新する場合は input のタグを変更して `nix flake update prismix` を実行し、API と activation の差分を確認する。

新しいインスタンスは同じモジュールの `programs.prismlauncher.instances` に別名の属性を追加する。
将来 Forge / NeoForge / Fabric を追加する際は、その Minecraft 版とローダーの互換性、Java 要求を確認し、
`minecraft.version`、`mod.loader.name` / `version`、`config.java` を個別設定する。
MOD は `mod.mods` の固定ハッシュ付きパスで追加する。Prismix は MOD の依存関係を自動解決しない。
保存先は各インスタンスの `minecraft/saves` になり、Vanilla と分離される。
既存インスタンスを管理へ取り込む際は、新しい名前にも Vanilla と同様の保護処理を拡張する。

## 検証

```sh
# リポジトリのルートで実行。いずれも switch しない。
nix-instantiate --parse home-manager/install-package/minecraft/default.nix >/dev/null
nix eval "path:$PWD#homeConfigurations.myHomeConfig.activationPackage.drvPath" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix" --no-write-lock-file --raw
nix build "path:$PWD#homeConfigurations.myHomeConfig.activationPackage" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix" --no-write-lock-file --no-link
nix eval "path:$PWD#nixosConfigurations.nixos.config.system.build.toplevel.drvPath" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix" --no-write-lock-file --raw
python3 tests/test_prismix_persistence.py
```

テストは一時 HOME で、実際に生成した設定と activation 断片を使う。
Minecraft の版・Java・メモリ、再適用と版変更による保存用ダミーデータの保持、
別インスタンス・未管理設定・認証用ダミーファイルの保持、既存 Vanilla / シンボリックリンクの拒否を検査する。
実際の NBT ワールドの起動テストではない。評価・ビルドはネット接続と Nix の利用権限が必要。

2026-11-10 の検証結果: 上記の構文確認・Home Manager 評価/ビルド・NixOS 評価は成功。
永続化テストは **3 件成功**。Java の `-version` は **25.0.5.0.3** を確認した。
CLI 構成と aarch64-darwin 構成の `programs.prismlauncher.enable` は `false`。
既存 flake input の固定値は全件不変で、Prismix と root の参照だけを追加した。
Microsoft 認証・ゲーム起動・実ワールドの保存/再読み込み・実ユーザーへの activation は未実施。

2026-11-11の追加検証: 旧MOD資産の登録・展開・テスト用Home Manager生成物のビルドと、
実ユーザー向けHome Manager / NixOSの評価に成功。永続化テストは **7件成功**。
旧ワールド・編集済み設定の保持、MOD変更やリンクの拒否、既存インスタンスの取り込みと設定バックアップ、
版が異なるインスタンスの拒否を確認した。実ユーザーの2インスタンスの読み取り専用の事前照合も成功。
システムへの適用とNix適用後のゲーム起動は未実施。

## 出典

- [NixOS Wiki: Prism Launcher](https://wiki.nixos.org/wiki/Prism_Launcher)
- [Prismix README / 最新 main](https://codeberg.org/OliMoli/prismix) と [v0.1.0 のオプション](https://codeberg.org/OliMoli/prismix/src/tag/v0.1.0/OPTIONS.md)
- [採用した Home Manager モジュール](https://codeberg.org/OliMoli/prismix/src/tag/v0.1.0/module/default.nix) と [ファイル生成処理](https://codeberg.org/OliMoli/prismix/src/tag/v0.1.0/module/lib/functions.nix)
- [Mojang のバージョン一覧](https://piston-meta.mojang.com/mc/game/version_manifest_v2.json) と [26.3 の公式メタデータ](https://piston-meta.mojang.com/v1/packages/80608ff6753705b6a82e2cb86a5937d4d233abd4/26.3.json)
- [Prism Launcher のインスタンス実装](https://github.com/PrismLauncher/PrismLauncher/blob/develop/launcher/minecraft/MinecraftInstance.cpp)
