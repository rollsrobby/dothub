"""Exercise ReGreet/Cage with two virtual outputs, without a GPU or real login."""
import os
import signal
import struct
import subprocess
import sys
import tempfile
import time
from pathlib import Path

widths = {}
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    for mode in ("extend", "last"):
        runtime = root / mode
        runtime.mkdir(mode=0o700)
        env = os.environ | {
            "XDG_RUNTIME_DIR": str(runtime),
            "WAYLAND_DISPLAY": "wayland-0",
            "WLR_BACKENDS": "headless",
            "WLR_HEADLESS_OUTPUTS": "2",
            "WLR_RENDERER": "pixman",
            "WLR_LIBINPUT_NO_DEVICES": "1",
            "GSK_RENDERER": "cairo",
            "GDK_BACKEND": "wayland",
        }
        with (runtime / "compositor.log").open("w+") as log:
            process = subprocess.Popen(
                [
                    "cage", "-d", "-m", mode, "--", "regreet", "--demo",
                    "--config", sys.argv[1], "--style", sys.argv[2],
                    "--logs", str(runtime / "regreet.log"),
                ],
                env=env, stdout=log, stderr=log, start_new_session=True,
            )
            try:
                # Bounded startup wait, followed by time for GTK to draw a frame.
                for _ in range(100):
                    if (runtime / "wayland-0").exists() or process.poll() is not None:
                        break
                    time.sleep(0.05)
                time.sleep(2)
                if process.poll() is not None:
                    log.seek(0)
                    raise RuntimeError(log.read())
                image = runtime / "screen.png"
                subprocess.run(["grim", str(image)], env=env, check=True)
                widths[mode] = struct.unpack(">I", image.read_bytes()[16:20])[0]
            finally:
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                process.wait(timeout=10)

# The old extended canvas combines both monitors; the fixed mode uses just one.
assert widths["last"] > 0 and widths["extend"] == 2 * widths["last"], widths
print(f"PASS: two-output canvas {widths['extend']}px -> single-output {widths['last']}px")
