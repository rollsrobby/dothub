"""Policy tests use fake hardware/commands; never lock or suspend the host."""
import importlib.util
import itertools
import os
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

spec = importlib.util.spec_from_file_location("policy", sys.argv.pop(1))
p = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = p
spec.loader.exec_module(p)


class PolicyTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.old_runtime = os.environ.get("XDG_RUNTIME_DIR")
        os.environ["XDG_RUNTIME_DIR"] = str(self.root)
        self.addCleanup(self.restore_runtime)

    def restore_runtime(self):
        if self.old_runtime is None:
            os.environ.pop("XDG_RUNTIME_DIR", None)
        else:
            os.environ["XDG_RUNTIME_DIR"] = self.old_runtime

    def write(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value)

    def test_policy_matrix(self):
        for ac, external, closed in itertools.product((False, True), repeat=3):
            state = p.State(ac, external, closed)
            with self.subTest(state=state):
                self.assertEqual(state.allows_suspend("battery"), not ac)
                self.assertEqual(state.allows_suspend("ac"), ac and not external)
                self.assertEqual(state.allows_suspend("lid"), closed and not (ac and external))

    def test_sysfs_adapter(self):
        self.write("sys/class/power_supply/AC/type", "USB_PD\n")
        self.write("sys/class/power_supply/AC/online", "1\n")
        self.write("sys/class/drm/card1-eDP-1/status", "connected\n")
        self.write("proc/acpi/button/lid/LID0/state", "state: closed\n")
        read = lambda: p.read_state(self.root / "sys", self.root / "proc")
        self.assertEqual(read(), p.State(True, False, True))
        self.write("sys/class/drm/card1-DP-3/status", "connected\n")
        self.assertEqual(read(), p.State(True, True, True))
        self.write("sys/class/power_supply/AC/online", "0\n")
        self.assertEqual(read(), p.State(False, True, True))

    def test_undock_closed_lid_and_debounce(self):
        monitor = p.LidMonitor()
        calls = []
        perform = lambda reason: calls.append(reason) or True
        docked = p.State(True, True, True)
        battery = p.State(False, True, True)
        monitor.tick(docked, 0, perform)
        monitor.tick(docked, 2, perform)
        monitor.tick(battery, 4, perform)
        self.assertEqual(calls, [])
        monitor.tick(battery, 6, perform)
        monitor.tick(battery, 8, perform)
        self.assertEqual(calls, ["lid"])
        # Reconnect AC, then remove the display: another unsafe transition.
        monitor.tick(docked, 10, perform)
        monitor.tick(p.State(True, False, True), 12, perform)
        monitor.tick(p.State(True, False, True), 14, perform)
        self.assertEqual(calls, ["lid", "lid"])

    def test_failed_lid_suspend_retries_without_spamming(self):
        monitor = p.LidMonitor()
        state = p.State(False, False, True)
        calls = []
        perform = lambda reason: calls.append(reason) or False
        for now in (0, 2, 4, 30, 32):
            monitor.tick(state, now, perform)
        self.assertEqual(calls, ["lid", "lid"])

    def test_lock_confirmation_required(self):
        calls = []
        now = [0]
        def pause(seconds):
            now[0] += seconds
        result = p.suspend("battery", state=lambda: p.State(False, False, False),
                           request_lock=lambda: None, run=lambda *a, **kw: calls.append(a),
                           clock=lambda: now[0], pause=pause)
        self.assertFalse(result)
        self.assertEqual(calls, [])

    def test_suspend_after_lock_and_recheck(self):
        calls = []
        def locked():
            (p.runtime() / "locked").touch()
        def run(command, **kwargs):
            calls.append(command)
            return SimpleNamespace(returncode=0)
        battery = p.State(False, True, True)
        self.assertTrue(p.suspend("lid", state=lambda: battery, request_lock=locked, run=run))
        self.assertEqual(calls, [["systemctl", "suspend"]])
        calls.clear()
        states = iter([battery, p.State(True, True, True)])
        self.assertFalse(p.suspend("lid", state=lambda: next(states), request_lock=locked, run=run))
        self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
