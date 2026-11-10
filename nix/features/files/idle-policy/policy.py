"""Dock-aware idle/lid policy. Hypridle owns idle timing and inhibition."""

from dataclasses import dataclass
import fcntl
import os
from pathlib import Path
import subprocess
import sys
import time


@dataclass(frozen=True)
class State:
    ac: bool
    external: bool
    lid_closed: bool

    def allows_suspend(self, reason):
        if reason == "battery":
            return not self.ac
        if reason == "ac":
            return self.ac and not self.external
        if reason == "lid":
            return self.lid_closed and not (self.ac and self.external)
        raise ValueError(reason)


def read_state(sysfs=Path("/sys"), proc=Path("/proc")):
    def text(path):
        try:
            return path.read_text().strip()
        except OSError:
            return ""

    ac = any(
        text(p / "type") in {"Mains", "USB", "USB_C", "USB_PD"}
        and text(p / "online") == "1"
        for p in (sysfs / "class/power_supply").glob("*")
    )
    # DPMS-off monitors remain connected and still count as external displays.
    external = any(
        not p.parent.name.split("-", 1)[-1].startswith(("eDP-", "LVDS-", "DSI-"))
        and text(p) == "connected"
        for p in (sysfs / "class/drm").glob("card*-*/status")
    )
    lid = any("closed" in text(p).lower() for p in (proc / "acpi/button/lid").glob("*/state"))
    return State(ac, external, lid)


def log(message):
    print(f"idle-policy: {message}", flush=True)


def runtime():
    directory = Path(os.environ["XDG_RUNTIME_DIR"]) / "idle-policy"
    directory.mkdir(mode=0o700, exist_ok=True)
    return directory


def lock():
    # Reuse an existing locker; avoid opening a second one on lid/idle overlap.
    existing = subprocess.run(["pgrep", "-u", str(os.getuid()), "-x", "hyprlock"],
                              stdout=subprocess.DEVNULL, check=False)
    if existing.returncode != 0:
        subprocess.Popen(["hyprlock"])


def suspend(reason, state=read_state, run=subprocess.run, request_lock=lock,
            clock=time.monotonic, pause=time.sleep):
    directory = runtime()
    with (directory / "suspend.lock").open("w") as guard:
        try:
            fcntl.flock(guard, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return False
        if not state().allows_suspend(reason):
            log(f"skip {reason}: power/display/lid state changed")
            return False
        request_lock()
        deadline = clock() + 10
        # Only Hypridle's compositor lock notification creates this marker.
        while not (directory / "locked").exists():
            if clock() >= deadline:
                log(f"refuse {reason} suspend: lock was not confirmed within 10 seconds")
                return False
            pause(0.1)
        if not state().allows_suspend(reason):
            log(f"skip {reason}: state changed while locking")
            return False
        log(f"suspend requested: {reason}")
        return run(["systemctl", "suspend"], check=False).returncode == 0


class LidMonitor:
    """Require two stable samples; retry failed locking/suspend after 30 seconds."""

    def __init__(self):
        self.previous = None
        self.handled = False
        self.retry_at = 0

    def tick(self, state, now, perform):
        if state != self.previous:
            self.previous, self.handled, self.retry_at = state, False, 0
            log(f"lid={'closed' if state.lid_closed else 'open'}, AC={state.ac}, external={state.external}")
            return
        if state.allows_suspend("lid") and not self.handled and now >= self.retry_at:
            self.handled = perform("lid")
            self.retry_at = now + 30


def main():
    command = sys.argv[1]
    if command == "lock":
        lock()
    elif command == "locked":
        (runtime() / "locked").touch()
    elif command in {"unlocked", "reset"}:
        (runtime() / "locked").unlink(missing_ok=True)
    elif command.startswith("check-"):
        reason = command.removeprefix("check-")
        allowed = read_state().allows_suspend(reason)
        log(f"idle {reason}: {'eligible' if allowed else 'deferred by AC/display policy'}")
        return 0 if allowed else 1
    elif command.startswith("suspend-"):
        return 0 if suspend(command.removeprefix("suspend-")) else 1
    elif command == "monitor-lid":
        monitor = LidMonitor()
        while True:
            monitor.tick(read_state(), time.monotonic(), suspend)
            time.sleep(2)
    else:
        raise ValueError(f"Unknown command: {command}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
