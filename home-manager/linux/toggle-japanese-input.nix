{ writeShellApplication, fcitx5, systemd, jq }:
writeShellApplication {
  name = "toggle-japanese-input";
  runtimeInputs = [ fcitx5 systemd jq ];
  text = builtins.readFile ./scripts/toggle-japanese-input.sh;
}
