# 入力メソッド一覧や辞書は Fcitx5 自身に管理させる。
# ~/.config/fcitx5/profile を Nix の固定ファイルで置き換えると、
# GUI からの入力メソッド一覧の変更と競合するため、公式の D-Bus API を使う。
# D-Bus は、起動中の Fcitx5 に「設定の取得・変更」を依頼する通信手段。
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
  echo 'Mozc and SKK must both be installed in Fcitx5.' >&2
  exit 1
}

# 現在のグループ（入力メソッドをまとめた一覧）の名前と設定を取得する。
# info の .data[0] はグループの既定配列、.data[1] は [入力メソッド名, 配列] の一覧。
group=$("${controller[@]}" --json=short CurrentInputMethodGroup | jq -er '.data[0] | select(length > 0)')
info=$("${controller[@]}" --json=short InputMethodGroupInfo s "$group")

# 現在のグループに Mozc / SKK が揃っていない場合だけ、不足分を追加する。
# 登録済みならこの処理を飛ばし、同じ項目を重複して追加しない。
if ! jq -e '[.data[1][][0]] | index("mozc") != null and index("skk") != null' \
  <<< "$info" >/dev/null; then
  # 既存の項目と配列はそのまま残し、未登録の入力メソッドだけ末尾へ追加する。
  # 追加項目の空の配列文字列は、グループの既定配列を使う指定。
  info=$(jq '
    reduce ["mozc", "skk"][] as $engine (. ;
      if any(.data[1][]; .[0] == $engine) then .
      else .data[1] += [[$engine, ""]] end)
  ' <<< "$info")
  # D-Bus に渡す引数を「既定配列、項目数、名前と配列の繰り返し」に並べる。
  # 空白区切りでは名前や空の文字列が壊れるため、NUL 文字で区切って配列にする。
  mapfile -d '' -t entries < <(jq -j '
    .data[0], "\u0000", (.data[1] | length), "\u0000",
    (.data[1][] | .[0], "\u0000", .[1], "\u0000")
  ' <<< "$info")
  # 変更した一覧を Fcitx5 に渡す。Fcitx5 がユーザープロファイルへ保存する。
  # ssa(ss) は引数の型で、文字列2つと「文字列2つの組」の配列を意味する。
  "${controller[@]}" SetInputMethodGroupInfo 'ssa(ss)' "$group" "${entries[@]}"
fi

# 最後に、決めておいた Mozc または SKK を選択する。
fcitx5-remote -s "$target"
