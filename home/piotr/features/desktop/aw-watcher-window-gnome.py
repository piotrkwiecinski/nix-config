import json
import os
import socket
import subprocess
import sys
import time
from datetime import datetime, timezone

import requests

HOSTNAME = socket.gethostname()
BUCKET = f"aw-watcher-window_{HOSTNAME}"
AW = os.environ.get("AW_SERVER_URL", "http://127.0.0.1:5600")
CLIENT = "aw-watcher-window-gnome-dbus"
POLL_SECONDS = 2.0
PULSETIME = 5.0


def create_bucket() -> None:
    try:
        requests.post(
            f"{AW}/api/0/buckets/{BUCKET}",
            json={
                "client": CLIENT,
                "type": "currentwindow",
                "hostname": HOSTNAME,
            },
            timeout=5,
        )
    except Exception as e:
        print(f"bucket create failed: {e}", file=sys.stderr)


def query_focused_window():
    try:
        out = subprocess.run(
            [
                "gdbus", "call", "--session",
                "--dest", "org.gnome.Shell",
                "--object-path", "/org/gnome/shell/extensions/FocusedWindow",
                "--method", "org.gnome.shell.extensions.FocusedWindow.Get",
            ],
            capture_output=True,
            text=True,
            timeout=3,
        )
    except Exception:
        return None
    if out.returncode != 0:
        return None
    raw = out.stdout.strip()
    # gdbus wraps the return in ('<json>',)
    if raw.startswith("('") and raw.endswith("',)"):
        payload = raw[2:-3]
    else:
        return None
    try:
        payload = payload.encode("utf-8").decode("unicode_escape")
    except Exception:
        pass
    try:
        return json.loads(payload)
    except Exception:
        return None


def send_heartbeat(app: str, title: str) -> None:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f+00:00")
    try:
        requests.post(
            f"{AW}/api/0/buckets/{BUCKET}/heartbeat",
            params={"pulsetime": str(PULSETIME)},
            json={
                "timestamp": now,
                "duration": 0,
                "data": {"app": app, "title": title},
            },
            timeout=5,
        )
    except Exception as e:
        print(f"heartbeat failed: {e}", file=sys.stderr)


def main() -> None:
    create_bucket()
    missing_logged = False
    while True:
        w = query_focused_window()
        if w is None:
            if not missing_logged:
                print(
                    "focused-window-dbus extension not reachable; "
                    "enable focused-window-dbus@flexagoon.com in GNOME Extensions",
                    file=sys.stderr,
                )
                missing_logged = True
        else:
            missing_logged = False
            app = w.get("wm_class") or "unknown"
            title = w.get("title") or "unknown"
            send_heartbeat(app, title)
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
