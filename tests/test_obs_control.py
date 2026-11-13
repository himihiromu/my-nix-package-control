"""Exercise v5 authentication and recording/replay state without a real OBS session."""
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from websockets.sync.client import connect
from websockets.sync.server import serve

SPEC = importlib.util.spec_from_file_location(
    "obs_control", Path(__file__).resolve().parents[1] / "home-manager/linux/obs-control.py")
control = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(control)


class FakeRequests:
    def __init__(self, active):
        self.active = active
        self.names = []
        self.pending = None

    def send(self, raw):
        self.pending = json.loads(raw)["d"]
        self.names.append(self.pending["requestType"])

    def recv(self, timeout):
        return json.dumps({"op": 7, "d": {
            "requestId": self.pending["requestId"], "requestStatus": {"result": True},
            "responseData": {"outputActive": self.active}}})


class ObsControlTest(unittest.TestCase):
    def test_duplicate_start_and_stop(self):
        for action, active in [("start", True), ("stop", False), ("replay-start", True), ("replay-stop", False)]:
            with self.subTest(action=action):
                ws = FakeRequests(active)
                control.operate(ws, action)
                self.assertEqual(len(ws.names), 1)

    def test_state_changes(self):
        for action, active, request in [("start", False, "StartRecord"), ("stop", True, "StopRecord"),
                                        ("replay-start", False, "StartReplayBuffer"),
                                        ("replay-stop", True, "StopReplayBuffer"),
                                        ("replay", True, "SaveReplayBuffer")]:
            with self.subTest(action=action):
                ws = FakeRequests(active)
                control.operate(ws, action)
                self.assertEqual(ws.names[-1], request)

    def test_inactive_replay_refused(self):
        ws = FakeRequests(False)
        with self.assertRaises(control.ControlError):
            control.operate(ws, "replay")
        self.assertEqual(ws.names, ["GetReplayBufferStatus"])

    def test_config_requires_private_authenticated_file(self):
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {"XDG_CONFIG_HOME": tmp}):
            path = Path(tmp) / "obs-studio/plugin_config/obs-websocket/config.json"
            path.parent.mkdir(parents=True)
            config = {"server_enabled": True, "auth_required": True,
                      "server_password": "test-only-password", "server_port": 4455}
            path.write_text(json.dumps(config))
            path.chmod(0o644)
            with self.assertRaises(control.ControlError):
                control.load_config()
            path.chmod(0o600)
            self.assertEqual(control.load_config(), (4455, "test-only-password"))
            config["auth_required"] = False
            path.write_text(json.dumps(config))
            with self.assertRaises(control.ControlError):
                control.load_config()

    def test_real_websocket_authentication(self):
        errors = []
        def handler(ws):
            try:
                ws.send(json.dumps({"op": 0, "d": {"authentication": {
                    "salt": "test-salt", "challenge": "test-challenge"}}}))
                message = json.loads(ws.recv())
                digest = lambda s: base64.b64encode(hashlib.sha256(s.encode()).digest()).decode()
                expected = digest(digest("test-only-password" + "test-salt") + "test-challenge")
                self.assertEqual(message["d"]["authentication"], expected)
                self.assertEqual(message["d"]["eventSubscriptions"], 0)
                ws.send(json.dumps({"op": 2, "d": {"negotiatedRpcVersion": 1}}))
                message = json.loads(ws.recv())["d"]
                self.assertEqual(message["requestType"], "GetRecordStatus")
                ws.send(json.dumps({"op": 7, "d": {
                    "requestId": message["requestId"], "requestStatus": {"result": True},
                    "responseData": {"outputActive": True}}}))
            except Exception as exc:
                errors.append(exc)
        with serve(handler, "127.0.0.1", 0) as server:
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            port = server.socket.getsockname()[1]
            with connect(f"ws://127.0.0.1:{port}", proxy=None) as ws:
                control.identify(ws, "test-only-password")
                self.assertTrue(control.request(ws, "GetRecordStatus")["outputActive"])
            server.shutdown()
            thread.join(5)
        self.assertFalse(errors, errors)

    def test_missing_obs_is_not_a_traceback(self):
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {"XDG_RUNTIME_DIR": tmp}), \
                patch.object(control, "load_config", return_value=(4455, "test-only-password")), \
                patch.object(control, "connect", side_effect=ConnectionRefusedError), \
                patch.object(control, "notify") as notify, patch("sys.argv", ["obs-control", "start"]):
            self.assertEqual(control.main(), 1)
            self.assertTrue(notify.call_args.args[1])
            self.assertNotIn("test-only-password", str(notify.call_args))


if __name__ == "__main__":
    unittest.main()
