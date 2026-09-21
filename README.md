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

## nix-darwin (macOS)

```shell
$ sudo nix run nix-darwin -- switch --flake .#mac-config
```

## Home Manager（単体）

```shell
$ nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig --show-trace
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
