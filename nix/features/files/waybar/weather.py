"""Compact Waybar weather with an atomic, last-successful-reading cache."""

import html
import json
import os
from pathlib import Path
import tempfile
from datetime import datetime
from urllib.request import urlopen


def reading(data):
    current = data["current_condition"][0]
    temperature = int(current["temp_C"])
    code = int(current["weatherCode"])
    # Use monochrome glyphs rather than variable-width emoji from the provider.
    if code == 113:
        icon = "󰖙"
    elif code in (116, 119, 122):
        icon = "󰖐"
    elif code in (143, 248, 260):
        icon = "󰖑"
    elif code in (200, 386, 389, 392, 395):
        icon = "󰖓"
    elif code in (179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320,
                  323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377):
        icon = "󰖘"
    else:
        icon = "󰖗"
    area = data["nearest_area"][0]
    location = ", ".join(area[key][0]["value"] for key in ("areaName", "country"))
    updated = datetime.now().astimezone().strftime("%b %d, %H:%M %Z")
    details = (
        f"{location}\n{current['weatherDesc'][0]['value']}\n"
        f"Feels like {current['FeelsLikeC']}°C · Humidity {current['humidity']}%\n"
        f"Wind {current['windspeedKmph']} km/h\nUpdated {updated}"
    )
    return {"text": f"{icon} {temperature}°C", "tooltip": html.escape(details), "class": "fresh"}


def weather(cache):
    try:
        # No location in the URL: preserve the existing public-IP geolocation.
        with urlopen("https://wttr.in/?format=j1", timeout=8) as response:
            result = reading(json.load(response))
    except (OSError, ValueError, KeyError, IndexError, TypeError):
        try:
            result = json.loads(cache.read_text())
            if not isinstance(result.get("text"), str) or not isinstance(result.get("tooltip"), str):
                raise ValueError("Invalid cached reading")
            result["class"] = "stale"
            result["tooltip"] += "\nStale: refresh failed. Click to retry."
            return result
        except (OSError, ValueError, AttributeError):
            return {"text": "󰖐 —", "tooltip": "Weather unavailable. Click to retry.", "class": "unavailable"}

    # Cache failures must never discard a successful live reading.
    temporary = None
    try:
        cache.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", dir=cache.parent, delete=False) as output:
            temporary = Path(output.name)
            json.dump(result, output)
        temporary.replace(cache)
    except OSError:
        pass
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    result["tooltip"] += "\nClick to refresh."
    return result


if __name__ == "__main__":
    cache_root = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    print(json.dumps(weather(cache_root / "waybar" / "weather.json")))
