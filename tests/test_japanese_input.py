"""専用の Fcitx5 / D-Bus を使う統合テスト。普段の入力環境には接続しない。

Python の dbus-next と、README に記載した実行ファイルを示す環境変数が必要。
"""
import asyncio
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

from dbus_next.aio import MessageBus
from dbus_next import Message, MessageType

FCITX = os.environ['FCITX5_TEST_BIN']
TOGGLE = os.environ['TOGGLE_JAPANESE_INPUT_BIN']
DBUS = os.environ['DBUS_DAEMON_TEST_BIN']
DEST = 'org.fcitx.Fcitx5'
CTRL = 'org.fcitx.Fcitx.Controller1'


class JapaneseInput(unittest.IsolatedAsyncioTestCase):
    async def start_fcitx(self, registered=('mozc', 'skk'), fcitx=FCITX):
        """一時 HOME と専用の通信先を作り、テスト用 Fcitx5 を起動する。"""
        self.tmp = tempfile.TemporaryDirectory(prefix='fcitx-switch-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        config = self.root / 'config/fcitx5'
        config.mkdir(parents=True)
        runtime = self.root / 'runtime'
        runtime.mkdir(mode=0o700)
        # 日本語・空白を含むグループ名と、入力メソッドごとの配列を使う。
        profile = '''[Groups/0]
Name=日本語 test
Default Layout=us
DefaultIM=mozc
[Groups/0/Items/0]
Name=keyboard-us
[Groups/0/Items/1]
Name=keyboard-jp
Layout=jp
[GroupOrder]
0=日本語 test
'''
        for index, name in enumerate(registered, start=2):
            profile += f'[Groups/0/Items/{index}]\nName={name}\n'
        (config / 'profile').write_text(profile)
        # 専用の D-Bus を使い、普段の Fcitx5 に設定変更が届かないようにする。
        bus_config = self.root / 'dbus.conf'
        bus_config.write_text(f'''<busconfig>
<type>session</type><listen>unix:tmpdir={self.root}</listen><auth>EXTERNAL</auth>
<policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy>
</busconfig>''')
        self.dbus = subprocess.Popen([DBUS, '--config-file=' + str(bus_config), '--nofork', '--print-address=1'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.addCleanup(self.stop, self.dbus)
        address = self.dbus.stdout.readline().strip()
        self.assertTrue(address, 'Private DBus failed to start' if address else self.dbus.stderr.read())
        # 設定・辞書・キャッシュの保存先も一時ディレクトリへ分離する。
        self.env = {k: v for k, v in os.environ.items() if k not in ('DISPLAY', 'WAYLAND_DISPLAY', 'SKIP_FCITX_USER_PATH')}
        self.env.update(HOME=str(self.root), XDG_CONFIG_HOME=str(self.root / 'config'), XDG_CONFIG_DIRS=str(self.root / 'etc'), XDG_DATA_HOME=str(self.root / 'data'), XDG_STATE_HOME=str(self.root / 'state'), XDG_CACHE_HOME=str(self.root / 'cache'), DBUS_SESSION_BUS_ADDRESS=address, XDG_RUNTIME_DIR=str(runtime))
        self.log = (self.root / 'fcitx.log').open('w+')
        self.addCleanup(self.log.close)
        self.fcitx = subprocess.Popen([fcitx, '--disable=wayland,xcb', '--ui=classicui'], env=self.env, stdout=self.log, stderr=self.log)
        self.addCleanup(self.stop, self.fcitx)
        self.bus = await MessageBus(bus_address=address).connect()
        self.addAsyncCleanup(self.disconnect)
        # 起動直後は通信できないため、Fcitx5 の準備が終わるまで待つ。
        deadline = time.monotonic() + 8
        while True:
            try:
                await self.controller('CurrentInputMethodGroup')
                break
            except AssertionError:
                if time.monotonic() > deadline:
                    self.log.seek(0)
                    self.fail(self.log.read())
                await asyncio.sleep(.1)
        # 文字入力欄を模した接続を作り、フォーカスのある Mozc 入力状態にする。
        reply = await self.call('/org/freedesktop/portal/inputmethod', 'org.fcitx.Fcitx.InputMethod1', 'CreateInputContext', 'a(ss)', [[['program', 'integration-test']]])
        self.context = reply[0]
        await self.call(self.context, 'org.fcitx.Fcitx.InputContext1', 'FocusIn')
        await self.controller('SetCurrentIM', 's', ['mozc'])

    @staticmethod
    def stop(proc):
        """テスト用プロセスとログ用パイプを終了・解放する。"""
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        for stream in (proc.stdout, proc.stderr):
            if stream:
                stream.close()

    async def disconnect(self):
        self.bus.disconnect()
        await self.bus.wait_for_disconnect()
        # Python 3.14 では dbus-next 0.2.x の切断後にソケットが残るため、明示的に閉じる。
        self.bus._stream.close()
        self.bus._sock.close()

    async def call(self, path, interface, member, signature='', body=None):
        """専用 D-Bus へ要求を送り、エラー応答ならテストを失敗させる。"""
        reply = await self.bus.call(Message(destination=DEST, path=path, interface=interface, member=member, signature=signature, body=body or []))
        self.assertNotEqual(reply.message_type, MessageType.ERROR, str(reply.body))
        return reply.body

    async def controller(self, member, signature='', body=None):
        """Fcitx5 の設定・選択状態を扱う API を呼ぶ。"""
        return await self.call('/controller', CTRL, member, signature, body)

    async def toggle(self, expected=0):
        """キーから呼ばれる実コマンドを実行し、終了コードを確認する。"""
        proc = await asyncio.create_subprocess_exec(TOGGLE, env=self.env, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        out, err = await asyncio.wait_for(proc.communicate(), timeout=10)
        self.assertEqual(proc.returncode, expected, (out + err).decode())

    async def test_toggle_and_existing_layout(self):
        """登録済みのエンジンを往復しても、一覧・配列が変わらないことを確認する。"""
        await self.start_fcitx()
        group = (await self.controller('CurrentInputMethodGroup'))[0]
        before = await self.controller('InputMethodGroupInfo', 's', [group])
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['skk'])
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['mozc'])
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['skk'])
        self.assertEqual(group, '日本語 test')
        self.assertEqual(await self.controller('InputMethodGroupInfo', 's', [group]), before)
        self.assertEqual(before, ['us', [['keyboard-us', ''], ['keyboard-jp', 'jp'], ['mozc', ''], ['skk', '']]])

    async def test_english_selects_mozc(self):
        """英数入力中の実行では Mozc が選ばれることを確認する。"""
        await self.start_fcitx()
        await self.controller('SetCurrentIM', 's', ['keyboard-us'])
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['mozc'])

    async def assert_no_change(self):
        """失敗時は選択中のエンジン・一覧・保存済みプロファイルを変えない。"""
        group = (await self.controller('CurrentInputMethodGroup'))[0]
        current = await self.controller('CurrentInputMethod')
        info = await self.controller('InputMethodGroupInfo', 's', [group])
        profile = self.root / 'config/fcitx5/profile'
        saved = profile.read_bytes()
        await self.toggle(expected=1)
        self.assertEqual(await self.controller('CurrentInputMethod'), current)
        self.assertEqual(await self.controller('InputMethodGroupInfo', 's', [group]), info)
        self.assertEqual(profile.read_bytes(), saved)

    async def test_missing_skk_registration(self):
        """SKK が未登録なら、自動登録も切り替えもしない。"""
        await self.start_fcitx(registered=('mozc',))
        await self.assert_no_change()

    async def test_missing_mozc_registration(self):
        """Mozc が未登録なら、自動登録も切り替えもしない。"""
        await self.start_fcitx(registered=('skk',))
        await self.assert_no_change()

    async def test_unavailable_skk(self):
        """SKK が未インストールなら、設定を変えず終了する。"""
        await self.start_fcitx(fcitx=os.environ['FCITX5_WITHOUT_SKK_TEST_BIN'])
        await self.assert_no_change()

    async def test_unavailable_mozc(self):
        """Mozc が未インストールなら、設定を変えず終了する。"""
        await self.start_fcitx(fcitx=os.environ['FCITX5_WITHOUT_MOZC_TEST_BIN'])
        await self.assert_no_change()


if __name__ == '__main__':
    unittest.main()
