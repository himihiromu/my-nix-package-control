{ config, lib, pkgs, utils, username, ... }:
let
  # このホストの /mnt 以下にある NTFS ボリュームだけを対象にする。
  volumes = lib.filterAttrs
    (path: fs: lib.hasPrefix "/mnt/" path && fs.fsType == "ntfs3")
    config.fileSystems;
  failureUnits = lib.concatMap (path:
    let
      name = utils.escapeSystemdPath path;
      handler = "mount-failure-notify@${name}.service";
      mkDropin = suffix: lib.nameValuePair "${name}.${suffix}" {
        overrideStrategy = "asDropin";
        text = ''
          [Unit]
          OnFailure=${handler}
        '';
      };
    in
    [ (mkDropin "mount") ]
    ++ lib.optional (builtins.elem "x-systemd.automount" volumes.${path}.options)
      (mkDropin "automount")
  ) (builtins.attrNames volumes);
in
{
  systemd.units = builtins.listToAttrs failureUnits;

  systemd.services."mount-failure-notify@" = {
    description = "Desktop notification for failed mount %f";
    # マウント本体と同時に失敗した automount も同じ通知サービスにまとめる。
    serviceConfig = {
      Type = "oneshot";
      User = username;
      RuntimeDirectory = "mount-failure-notify";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = "yes";
    };
    environment = {
      MOUNT_PATH = "%f";
      MOUNT_NAME = "%i";
    };
    path = [ pkgs.coreutils pkgs.systemd pkgs.libnotify ];
    script = ''
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

      # GUI 未ログイン時は journal のみに残し、通知デーモンを起動しない。
      if ! systemctl --user --quiet is-active graphical-session.target; then
        echo "Mount failed: $MOUNT_PATH (no graphical session)"
        exit 0
      fi

      # Steam などが連続アクセスしても、同じディスクの通知は60秒に1回まで。
      stamp="$RUNTIME_DIRECTORY/$MOUNT_NAME"
      now=$(date +%s)
      previous=0
      if [ -f "$stamp" ]; then
        previous=$(cat "$stamp")
      fi
      if [ "$((now - previous))" -lt 60 ]; then
        exit 0
      fi

      notify-send --app-name="ディスク監視" --urgency=critical \
        --icon=drive-harddisk --expire-time=0 \
        "ディスクのマウントに失敗しました" \
        "$MOUNT_PATH が利用できません。journalctl -b -u $MOUNT_NAME.mount で詳細を確認してください。"
      printf '%s\n' "$now" > "$stamp"
    '';
  };
}
