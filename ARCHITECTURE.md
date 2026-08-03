# Home Manager / NixOS 設計ルール

本リポジトリは NixOS + Home Manager + chezmoi を利用した Linux/macOS 環境を管理する。

## 基本方針

| 役割 | 担当 | 例 |
|------|------|-----|
| Home Manager | パッケージのインストールとサービス起動 | `home.packages`, `services.*.enable` |
| chezmoi | アプリケーション設定ファイルの管理 | `~/.config/hypr/hyprland.conf` |
| NixOS | OS全体に関わる機能 | Boot, Hardware, Networking, PipeWire |

まずはデフォルト設定で利用し、不満が出たタイミングで設定を追加する。

## Home Manager 利用順序

優先度が高い順に検討し、必要性が明確になるまで次の段階には進めない。

1. `home.packages` — パッケージのインストールのみ
2. `services.*` — 常駐サービスの有効化
3. `programs.*` — Home Manager に設定生成を任せる場合のみ
4. chezmoi で設定追加 — 設定ファイルが必要になった場合

Home Manager による設定ファイル生成は極力行わない。

## パッケージ分類

### Desktop Environment（DE依存）

デスクトップ環境と運命共同体のパッケージ。DEを切り替える際にまとめて差し替える対象。

`home-manager/desktop/hyprland.nix`

- hyprlock
- hypridle
- hyprpaper
- hyprpolkitagent
- xdg-desktop-portal-hyprland
- hyprpicker

### Linux Desktop（DE非依存）

デスクトップ環境に依存しないGUIアプリケーション。DEを変えてもそのまま使える。

`home-manager/linux/desktop.nix`

- Ghostty
- Zen Browser
- Chromium
- Vicinae
- Clipse
- Nemo
- Waypaper
- Waybar
- SwayNC
- brightnessctl

### Multimedia

録画・スクリーンショット・音声関連。

`home-manager/linux/multimedia.nix`

- gpu-screen-recorder
- obs-studio
- grimblast
- satty
- pamixer
- pavucontrol

## ディレクトリ構成

```
nixos/                          # NixOS ホスト設定（bare metal）
├── configuration.nix           # エントリポイント
├── hardware-configuration.nix  # インストーラー生成ファイル
└── system/
    ├── hardware.nix            # AMD CPU/GPU, Firmware, Bluetooth
    ├── desktop.nix             # Hyprland, greetd, PipeWire, Locale, Fonts, Fcitx5
    ├── services.nix            # NetworkManager, Firewall, Docker, Avahi
    └── nix.nix                  # nix settings, GC, Store optimise

home-manager/
├── default.nix              # エントリポイント。OS判定してパッケージを組み立て
├── desktop/
│   └── hyprland.nix          # DE依存パッケージ（Hyprland）
├── linux/
│   ├── default.nix           # desktop + multimedia + hyprland を集約
│   ├── desktop.nix           # DE非依存GUIアプリ
│   ├── multimedia.nix        # マルチメディア関連
│   └── services.nix          # Home Manager モジュール（services.*.enable）
├── install-package/
│   ├── common.nix            # 全OS共通パッケージ
│   └── darwin.nix            # macOS専用パッケージ
└── shell/                    # シェル設定
```

## NixOS モジュール責務

### nix.nix

Nix daemon の設定とメンテナンス。

- `nix.settings` — experimental-features, trusted-users, substituters
- `nix.gc` — 自動ガベージコレクション（weekly, 30d）
- `nix.optimise` — 自動ストア最適化（weekly）

### hardware.nix

ハードウェアサポート。

- AMD CPU Microcode, AMDGPU, Mesa（32bit含む）
- 最新安定Kernel
- Bluetooth, Redistributable Firmware

### desktop.nix

デスクトップ環境。デスクトップアプリは含めない。

- Hyprland（system-wide enable）
- greetd + tuigreet
- PipeWire（ALSA/PulseAudio/JACK互換）
- xdg.portal, polkit
- Locale（ja_JP / en_US）, Timezone（Asia/Tokyo）
- Fonts（Noto, Noto CJK, Noto Color Emoji, JetBrainsMono Nerd）
- Fcitx5 + Mozc + SKK
- xdg-user-dirs

### services.nix

OS基盤サービス。

- NetworkManager, Firewall
- Docker（rootless）
- systemd-timesyncd, Avahi

## 実装ルール

- import によりモジュールを構成する
- 独自 enable オプションは極力追加しない
- 将来的に細分化できるよう、現在は過度に分割しない
- AIエージェントは本ルールを優先し、設計との整合性を確認してから実装する

## chezmoi で管理する設定

以下は必要になったタイミングで chezmoi に追加する。

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/ghostty`
- `~/.config/swaync`
- `~/.config/clipse`
- `~/.config/nemo`
