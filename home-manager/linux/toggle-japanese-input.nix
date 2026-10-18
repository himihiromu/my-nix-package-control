{ writeShellApplication, fcitx5, systemd, jq }:
# スクリプトを実行コマンドとしてパッケージ化する。
# 構文検証と ShellCheck による検査もビルド時に行われる。
writeShellApplication {
  name = "toggle-japanese-input";
  # fcitx5 は選択用コマンド、systemd は D-Bus 通信用の busctl、
  # jq は応答 JSON の読み取りに使う。実行時の PATH に自動で追加される。
  runtimeInputs = [ fcitx5 systemd jq ];
  # 処理本体は、読みやすいように別のシェルスクリプトに分けている。
  text = builtins.readFile ./scripts/toggle-japanese-input.sh;
}
