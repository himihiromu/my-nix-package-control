# Fcitx owns its mutable profile and dictionaries. Update the active group via
# its controller instead of replacing ~/.config/fcitx5/profile from Nix.
controller=(busctl --user --timeout=5 call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1)

current=$(fcitx5-remote -n)
case "$current" in
  mozc) target=skk ;;
  *) target=mozc ;;
esac

# Both engines must be available before changing the group.
available=$("${controller[@]}" --json=short AvailableInputMethods)
jq -e '[.data[0][][0]] | index("mozc") != null and index("skk") != null' \
  <<< "$available" >/dev/null || {
  echo 'Mozc and SKK must both be installed in Fcitx5.' >&2
  exit 1
}

group=$("${controller[@]}" --json=short CurrentInputMethodGroup | jq -er '.data[0] | select(length > 0)')
info=$("${controller[@]}" --json=short InputMethodGroupInfo s "$group")

if ! jq -e '[.data[1][][0]] | index("mozc") != null and index("skk") != null' \
  <<< "$info" >/dev/null; then
  info=$(jq '
    reduce ["mozc", "skk"][] as $engine (. ;
      if any(.data[1][]; .[0] == $engine) then .
      else .data[1] += [[$engine, ""]] end)
  ' <<< "$info")
  # NUL separators preserve spaces, non-ASCII names, and empty layout strings.
  mapfile -d '' -t entries < <(jq -j '
    .data[0], "\u0000", (.data[1] | length), "\u0000",
    (.data[1][] | .[0], "\u0000", .[1], "\u0000")
  ' <<< "$info")
  "${controller[@]}" SetInputMethodGroupInfo 'ssa(ss)' "$group" "${entries[@]}"
fi

fcitx5-remote -s "$target"
