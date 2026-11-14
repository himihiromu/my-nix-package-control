# 工業と魔術: Minecraft 1.20.1

確認日: 2026-11-14。出典: 2026-11-13にユーザーが1.20系を選択。2026-11-14に最適化MOD3つとInventory Tweaks ReFoxedの追加・起動確認を依頼。

## 構成

- PrismのインスタンスID: `Industry-Magic-1.20.1`
- 表示名: **Industry & Magic 1.20.1**
- Minecraft **1.20.1** / Forge **47.4.28** / Java **17**
- メモリ: 最小1024 MiB / 最大8192 MiB。初期表示は日本語、描画距離8チャンク。
- Nixモジュール: `home-manager/install-package/minecraft/modern.nix`
- 固定ファイル: `home-manager/install-package/minecraft/modern-lock.json`

## 選定したMOD

| 分類 | MOD |
| --- | --- |
| 工業 | Create、Mekanism、Mekanism Generators、Industrial Foregoing、Ender IO |
| Thermal | Foundation、Expansion、Dynamics、Cultivation、Innovation、Locomotion |
| 倉庫・連携 | AE2、Applied Mekanistics、Applied Create、Compact Machines |
| 魔術 | Ars Nouveau、Ars Creo、Occultism、Ars Ocultas、Iron's Spells 'n Spellbooks |
| 生産・生活 | Productive Bees、Farmer's Delight |
| 鉄道・採掘 | Railcraft Reborn、RFTools Builder |
| 装備 | Tinkers' Construct、Silent Gear |
| 操作支援 | EMI、Xaero's Minimap、FTB Ultimine |
| 最適化 | Embeddium 0.3.31、ModernFix 5.27.93、FerriteCore 6.0.1 |
| 持ち物・チェスト整理 | Inventory Tweaks ReFoxed 1.2.2 |

Modern Industrializationは1.20.1版のローダーがFabricのため除外。
Applied CreateとOccultismの重複指定はそれぞれ1つに整理した。
JEIは各MODのレシピ連携用としてEMIと併用し、必要なライブラリを含めて52個のJARを固定した。
Touhou Little Maidは2026-11-13のユーザー依頼で除外した。配信・収益化の素材利用条件を確認できていないための判断であり、配信禁止と断定したものではない。
除外前のJAR・固定情報・セーブのバックアップは、当該インスタンスの `removed-mods/<日時>/` に保存している。
一部MODはベータ配布版を使用している。依存ライブラリは配布メタデータとJAR内の `mods.toml` の両方で確認した。

## 再現とデータ保持

Nixは固定URLとSHA-256でMODを取得する。Compact MachinesとInventory Tweaks ReFoxedはCurseForge、
FTB Ultimine / FTB Libraryは開発元Maven、ほかはModrinthの配布URLを使用する。
Inventory Tweaks ReFoxedはCurseForgeの1.20.1 Forge向け1.2.2を使用する。
旧1.7.10環境用のローカルアーカイブとは別の仕組みで、この構成自体は元ディスクを必要としない。

Prismの保存先は `$XDG_DATA_HOME/PrismLauncher/instances/Industry-Magic-1.20.1/minecraft`。
`saves` は通常のユーザーデータとして保持し、Nix Storeへ入れない。
再適用では不足MODだけをコピーし、既存MODの内容が固定値と違う場合やゲーム起動中は停止する。
ゲーム内で変更した `options.txt` とMOD設定は保持する。
既存環境の取り込み前に `instance.cfg` / `mmc-pack.json` を `.legacy-before-nix/` に保管する。

MOD更新時はゲームを終了し、セーブと既存MODを退避してから固定ファイルと実体を揃える。
ロックだけ変更して既存ファイルを強制上書きする処理はない。
1.7.10のワールドをこの環境へ移行する処理も行わない。

## 検証結果

- 初回は49個のJARを配置。Touhou Little Maid除外後の48個に、最適化・整理MODを4つ追加し、現在は52個。配布ハッシュとSHA-256を照合した。
- JAR内の必須MODの不足は0件。同梱ライブラリも検査した。
- Forge 47.4.28 / Java 17でゲームが起動し、描画・音声初期化とEMIのレシピ構築を確認した。
- ログで新規ワールドの起動とチャンク保存を確認した。各MODの全機能・全レシピを検証したものではない。
- Compact Machinesの一部テクスチャとEnder IOの一部モデルの読み込みエラーをログで確認。クラッシュレポートは生成されていない。該当ブロックの描画は未確認。
- `python3 tests/test_prismix_persistence.py`: **10件成功**。追加4 MODの配置、旧環境と新環境の再適用時のデータ保持、LWJGL 3を含む既存環境の取り込みなどを確認した。
- テスト用Home Manager生成物をビルドした。実ユーザーへのHome Manager / NixOSのswitchは実施していない。

2026-11-14の追加時はゲーム終了を確認し、既存セーブ・config・options・ランチャー設定を
インスタンス内の `change-backups/<日時>-performance/user-data-before.tar.gz` へ保存した。
追加後の起動ログで4つのMODの読み込み、EmbeddiumのOpenGL初期化、音声とテクスチャ初期化を確認。
ModernFixの起動時間ログは14.4秒だったが、同条件の比較測定は行っていない。
ReFoxedの設定ファイル生成と整理ボタン有効の初期設定を確認した。実際のチェスト整理操作は未検証。
ReFoxedの初期設定ではAE2端末やThermal機械など一部のGUIが整理対象から除外される。

## 配布元

- [Forge 1.20.1](https://files.minecraftforge.net/net/minecraftforge/forge/index_1.20.1.html): 推奨版47.4.28を採用。
- [Modrinth API](https://docs.modrinth.com/api/): Forge / 1.20.1に絞り、個別ファイルと必須依存を照合。
- [Compact Machines 6.0.3](https://www.curseforge.com/minecraft/mc-mods/compact-machines/files/6000230)
- [FTB Ultimine 2001.1.7](https://maven.ftb.dev/releases/dev/ftb/mods/ftb-ultimine-forge/2001.1.7/)
- [FTB Library 2001.2.12](https://maven.ftb.dev/releases/dev/ftb/mods/ftb-library-forge/2001.2.12/)
- [Inventory Tweaks ReFoxed 1.2.2](https://www.curseforge.com/minecraft/mc-mods/inventory-tweaks-refoxed/files/6816947)
