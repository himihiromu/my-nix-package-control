"""Integration test against a private Fcitx/DBus session, never the user's IME.

Requires Python dbus-next and FCITX5_TEST_BIN / TOGGLE_JAPANESE_INPUT_BIN.
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
    async def asyncSetUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='fcitx-switch-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        config = self.root / 'config/fcitx5'
        config.mkdir(parents=True)
        runtime = self.root / 'runtime'
        runtime.mkdir(mode=0o700)
        # Deliberately non-ASCII group, US layout, and missing SKK.
        (config / 'profile').write_text('''[Groups/0]
Name=日本語 test
Default Layout=us
DefaultIM=mozc
[Groups/0/Items/0]
Name=keyboard-us
[Groups/0/Items/1]
Name=mozc
[Groups/0/Items/2]
Name=keyboard-jp
Layout=jp
[GroupOrder]
0=日本語 test
''')
        bus_config = self.root / 'dbus.conf'
        bus_config.write_text(f'''<busconfig>
<type>session</type><listen>unix:tmpdir={self.root}</listen><auth>EXTERNAL</auth>
<policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy>
</busconfig>''')
        self.dbus = subprocess.Popen([DBUS, '--config-file=' + str(bus_config), '--nofork', '--print-address=1'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.addCleanup(self.stop, self.dbus)
        address = self.dbus.stdout.readline().strip()
        self.assertTrue(address, 'Private DBus failed to start' if address else self.dbus.stderr.read())
        self.env = {k: v for k, v in os.environ.items() if k not in ('DISPLAY', 'WAYLAND_DISPLAY', 'SKIP_FCITX_USER_PATH')}
        self.env.update(HOME=str(self.root), XDG_CONFIG_HOME=str(self.root / 'config'), XDG_CONFIG_DIRS=str(self.root / 'etc'), XDG_DATA_HOME=str(self.root / 'data'), XDG_STATE_HOME=str(self.root / 'state'), XDG_CACHE_HOME=str(self.root / 'cache'), DBUS_SESSION_BUS_ADDRESS=address, XDG_RUNTIME_DIR=str(runtime))
        self.log = (self.root / 'fcitx.log').open('w+')
        self.addCleanup(self.log.close)
        self.fcitx = subprocess.Popen([FCITX, '--disable=wayland,xcb', '--ui=classicui'], env=self.env, stdout=self.log, stderr=self.log)
        self.addCleanup(self.stop, self.fcitx)
        self.bus = await MessageBus(bus_address=address).connect()
        self.addAsyncCleanup(self.disconnect)
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
        reply = await self.call('/org/freedesktop/portal/inputmethod', 'org.fcitx.Fcitx.InputMethod1', 'CreateInputContext', 'a(ss)', [[['program', 'integration-test']]])
        self.context = reply[0]
        await self.call(self.context, 'org.fcitx.Fcitx.InputContext1', 'FocusIn')
        await self.controller('SetCurrentIM', 's', ['mozc'])

    @staticmethod
    def stop(proc):
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
        # dbus-next 0.2.x leaves the socket open after disconnect on Python 3.14.
        self.bus._stream.close()
        self.bus._sock.close()

    async def call(self, path, interface, member, signature='', body=None):
        reply = await self.bus.call(Message(destination=DEST, path=path, interface=interface, member=member, signature=signature, body=body or []))
        self.assertNotEqual(reply.message_type, MessageType.ERROR, str(reply.body))
        return reply.body

    async def controller(self, member, signature='', body=None):
        return await self.call('/controller', CTRL, member, signature, body)

    async def toggle(self):
        proc = await asyncio.create_subprocess_exec(TOGGLE, env=self.env, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        out, err = await asyncio.wait_for(proc.communicate(), timeout=10)
        self.assertEqual(proc.returncode, 0, (out + err).decode())

    async def test_registration_toggle_and_existing_layout(self):
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['skk'])
        group = (await self.controller('CurrentInputMethodGroup'))[0]
        self.assertEqual(group, '日本語 test')
        self.assertEqual(await self.controller('InputMethodGroupInfo', 's', [group]), ['us', [['keyboard-us', ''], ['mozc', ''], ['keyboard-jp', 'jp'], ['skk', '']]])
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['mozc'])
        # Repeated use must not duplicate registered methods.
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['skk'])
        info = await self.controller('InputMethodGroupInfo', 's', [group])
        self.assertEqual(len(info[1]), 4)
        self.assertIn('Name=skk', (self.root / 'config/fcitx5/profile').read_text())

    async def test_english_selects_mozc(self):
        await self.controller('SetCurrentIM', 's', ['keyboard-us'])
        await self.toggle()
        self.assertEqual(await self.controller('CurrentInputMethod'), ['mozc'])


if __name__ == '__main__':
    unittest.main()
