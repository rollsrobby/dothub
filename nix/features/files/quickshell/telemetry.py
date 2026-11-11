"""Read-only Linux status adapter; policy stays in power-profile-policy."""
import json
import os
from pathlib import Path
import subprocess
import time


def command(*args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=3,
                              check=True, env=dict(os.environ, LC_ALL="C")).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def fields(line):
    """Split nmcli's escaped terse fields (SSID names can contain colons)."""
    result, field, escaped = [], "", False
    for char in line:
        if escaped:
            field += char
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            result.append(field)
            field = ""
        else:
            field += char
    return result + [field]


def privacy(nodes):
    result = {"microphone": [], "screenshare": []}
    for node in nodes:
        info = node.get("info", {})
        props = info.get("props", {})
        if info.get("state") != "running" or str(props.get("stream.monitor", "")).lower() == "true":
            continue
        kind = {"Stream/Input/Audio": "microphone", "Stream/Input/Video": "screenshare"}.get(props.get("media.class"))
        if kind:
            result[kind].append(props.get("application.name") or props.get("node.name") or "Unknown application")
    return result


def resources(previous):
    ticks = [int(x) for x in Path("/proc/stat").read_text().splitlines()[0].split()[1:9]]
    total, idle = sum(ticks), ticks[3] + ticks[4]
    delta = total - previous[0] if previous else 0
    cpu = round(100 * (1 - (idle - previous[1]) / delta)) if delta else 0
    memory = {line.split(":")[0]: int(line.split()[1]) for line in Path("/proc/meminfo").read_text().splitlines()}
    used = memory["MemTotal"] - memory["MemAvailable"]
    swap = memory["SwapTotal"] - memory["SwapFree"]
    swap_percent = round(100 * swap / memory["SwapTotal"]) if memory["SwapTotal"] else 0
    gib = 1024 ** 2
    ram = round(100 * used / memory["MemTotal"])
    return {"cpu": cpu, "load": os.getloadavg()[0], "ram": ram,
            "memoryTip": f'Memory: {used/gib:.1f}/{memory["MemTotal"]/gib:.1f} GiB ({ram}%)\nZram: {swap/gib:.1f}/{memory["SwapTotal"]/gib:.1f} GiB ({swap_percent}%)'}, (total, idle)


def network(previous):
    devices = [fields(line) for line in command("nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device").splitlines()]
    device = next((d for d in devices if len(d) == 4 and d[1] in ("wifi", "ethernet") and d[2] == "connected"), None)
    if not device:
        return {"text": "󰤮", "connected": False, "tooltip": "Disconnected"}, None
    interface, kind, _, name = device
    now = time.monotonic()
    try:
        stats = Path("/sys/class/net") / interface / "statistics"
        rx, tx = (int((stats / f"{direction}_bytes").read_text()) for direction in ("rx", "tx"))
    except OSError:
        rx = tx = 0
    down = up = 0
    if previous and previous[0] == interface:
        elapsed = max(0.001, now - previous[1])
        down, up = max(0, rx - previous[2]) / elapsed, max(0, tx - previous[3]) / elapsed
    text = "󰀂 LAN"
    if kind == "wifi":
        aps = [fields(line) for line in command("nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,FREQ", "device", "wifi", "list", "--rescan", "no", "ifname", interface).splitlines()]
        ap = next((a for a in aps if len(a) == 4 and a[0] == "*"), None)
        signal = int(ap[2]) if ap and ap[2].isdigit() else 0
        text = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][min(4, signal // 20)] + " Wi-Fi"
        if ap:
            name = f"{ap[1]} ({ap[3]})"
    return {"text": text, "connected": True, "tooltip": f"{name}\n⇣{down/1024:.1f} KiB/s  ⇡{up/1024:.1f} KiB/s"}, (interface, now, rx, tx)


def main():
    cpu_previous = net_previous = None
    while True:
        data, cpu_previous = resources(cpu_previous)
        data["network"], net_previous = network(net_previous)
        try:
            data["privacy"] = privacy(json.loads(command("pw-dump") or "[]"))
        except ValueError:
            data["privacy"] = privacy([])
        data["bluetooth"] = command("bluetoothctl", "devices", "Connected").splitlines()
        data["bluetoothPowered"] = "Powered: yes" in command("bluetoothctl", "show")
        failed = []
        for scope in ([], ["--user"]):
            failed.extend(command("systemctl", *scope, "--failed", "--no-legend", "--plain", "--no-pager").splitlines())
        data["failed"] = failed
        print(json.dumps(data), flush=True)
        time.sleep(3)


if __name__ == "__main__":
    main()
