"""Short-lived OBS WebSocket v5 client. Credentials never enter Nix evaluation."""
import argparse
import base64
import fcntl
import hashlib
import json
import os
from pathlib import Path
import socket
import stat
import subprocess
import sys
import uuid

from websockets.sync.client import connect


class ControlError(Exception):
    pass


def notify(message, error=False):
    print(message, file=sys.stderr if error else sys.stdout)
    try:
        subprocess.run(
            ["notify-send", "--app-name=OBS", "--urgency=" + ("critical" if error else "normal"),
             "OBS", message], check=False, timeout=3, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass


def load_config():
    path = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    path /= "obs-studio/plugin_config/obs-websocket/config.json"
    # Refuse symlinks (including Nix store links) and files readable by other users.
    with os.fdopen(os.open(path, os.O_RDONLY | os.O_NOFOLLOW)) as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
            raise ControlError("OBS WebSocket設定を本人所有の通常ファイル・権限600にしてください。")
        config = json.load(stream)
    if not config.get("server_enabled"):
        raise ControlError("OBSのWebSocketサーバーを有効にしてください。")
    if not config.get("auth_required") or not config.get("server_password"):
        raise ControlError("OBSのWebSocket認証を有効にしてパスワードを設定してください。")
    port = config.get("server_port", 4455)
    if type(port) is not int or not 1 <= port <= 65535:
        raise ControlError("OBS WebSocketのポート設定が不正です。")
    return port, config["server_password"]


def digest(value):
    return base64.b64encode(hashlib.sha256(value.encode()).digest()).decode()


def identify(ws, password):
    hello = json.loads(ws.recv(timeout=5))
    if hello.get("op") != 0 or not hello.get("d", {}).get("authentication"):
        raise ControlError("認証付きOBS WebSocket v5サーバーではありません。")
    auth = hello["d"]["authentication"]
    response = digest(digest(password + auth["salt"]) + auth["challenge"])
    ws.send(json.dumps({"op": 1, "d": {"rpcVersion": 1, "eventSubscriptions": 0,
                                      "authentication": response}}))
    if json.loads(ws.recv(timeout=5)).get("op") != 2:
        raise ControlError("OBS WebSocketの認証に失敗しました。")


def request(ws, name):
    request_id = str(uuid.uuid4())
    ws.send(json.dumps({"op": 6, "d": {"requestType": name, "requestId": request_id}}))
    message = json.loads(ws.recv(timeout=5))
    data = message.get("d", {})
    if message.get("op") != 7 or data.get("requestId") != request_id:
        raise ControlError("OBSから予期しない応答が返りました。")
    status = data.get("requestStatus", {})
    if not status.get("result"):
        # Never print server comments, paths, credentials or raw protocol messages.
        raise ControlError(f"OBS操作 {name} が失敗しました（コード {int(status.get('code', 0))}）。")
    return data.get("responseData", {})


def operate(ws, action):
    if action == "status":
        record = request(ws, "GetRecordStatus")
        replay = request(ws, "GetReplayBufferStatus")
        return "録画: {} / リプレイ: {}".format(
            "一時停止" if record.get("outputPaused") else "実行中" if record["outputActive"] else "停止",
            "実行中" if replay["outputActive"] else "停止")
    is_replay = action.startswith("replay")
    active = request(ws, "GetReplayBufferStatus" if is_replay else "GetRecordStatus")["outputActive"]
    if action == "replay":
        if not active:
            raise ControlError("リプレイバッファは停止中です。obs-control replay-start で開始してください。")
        request(ws, "SaveReplayBuffer")
        return "リプレイ保存を要求しました。"
    start = action in ("start", "replay-start")
    label = "リプレイバッファ" if is_replay else "録画"
    if active == start:
        return label + ("は既に実行中です。" if active else "は既に停止しています。")
    request(ws, ("Start" if start else "Stop") + ("ReplayBuffer" if is_replay else "Record"))
    return label + ("を開始しました。" if start else "を停止しました。")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["start", "stop", "replay", "status", "replay-start", "replay-stop"])
    args = parser.parse_args()
    try:
        runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
        with os.fdopen(os.open(runtime / "obs-control.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600), "w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise ControlError("別のOBS操作を実行中です。") from None
            port, password = load_config()
            # A numeric loopback address and proxy=None prevent remote/proxy connections.
            with connect(f"ws://127.0.0.1:{port}", proxy=None, open_timeout=5,
                         close_timeout=1, max_size=1024 * 1024) as ws:
                identify(ws, password)
                password = None
                message = operate(ws, args.action)
        notify(message)
        return 0
    except ControlError as exc:
        notify(str(exc), True)
    except FileNotFoundError:
        notify("OBSのWebSocket設定またはユーザー実行時ディレクトリがありません。初期設定を確認してください。", True)
    except (ConnectionRefusedError, socket.timeout, TimeoutError):
        notify("OBSに接続できません。OBSの起動とWebSocket設定を確認してください。", True)
    except Exception:
        # Authentication and protocol errors may contain sensitive data: do not log exceptions.
        notify("OBS操作に失敗しました。認証・設定・接続状態を確認してください。", True)
    return 1


if __name__ == "__main__":
    sys.exit(main())
