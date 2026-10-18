# インストールや入力メソッドの自動登録は行わず、登録済みの Mozc / SKK を選択する。
# D-Bus は起動中の Fcitx5 に利用可能なエンジンや登録状態を問い合わせる通信手段。
# 以下の配列に共通の呼び出し先をまとめ、通信の待ち時間は最大5秒にする。
controller=(busctl --user --timeout=5 call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1)

# 現在の入力メソッド名を取得して、切り替え先を決める。
# Mozc 使用中なら SKK、それ以外（SKK・英数入力など）なら Mozc を選ぶ。
current=$(fcitx5-remote -n)
case "$current" in
  mozc) target=skk ;;
  *) target=mozc ;;
esac

# まず、Fcitx5 が利用できる入力メソッドに Mozc と SKK があるか確認する。
# jq は D-Bus の応答 JSON を読み取る道具。
# .data[0] が入力メソッド一覧で、各項目の [0] が内部名（mozc / skk）。
# 片方が未インストールなら、設定を変更する前に終了する。
available=$("${controller[@]}" --json=short AvailableInputMethods)
jq -e '[.data[0][][0]] | index("mozc") != null and index("skk") != null' \
  <<< "$available" >/dev/null || {
  echo 'Mozc と SKK を Nix 側でインストールしてください。' >&2
  exit 1
}

# 現在のグループ（入力メソッドをまとめた一覧）の名前と設定を取得する。
# info の .data[0] はグループの既定配列、.data[1] は [入力メソッド名, 配列] の一覧。
group=$("${controller[@]}" --json=short CurrentInputMethodGroup | jq -er '.data[0] | select(length > 0)')
info=$("${controller[@]}" --json=short InputMethodGroupInfo s "$group")

# インストール済みでも、現在のグループに未登録なら切り替えられない。
# 不足分の追加やプロファイルの書き換えはせず、そのまま終了する。
jq -e '[.data[1][][0]] | index("mozc") != null and index("skk") != null' \
  <<< "$info" >/dev/null || {
  echo '現在の Fcitx5 グループに Mozc と SKK の両方を登録してください。' >&2
  exit 1
}

# 最後に、決めておいた Mozc または SKK を選択する。
fcitx5-remote -s "$target"
