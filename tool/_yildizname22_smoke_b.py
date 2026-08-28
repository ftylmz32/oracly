# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_yildizname_gate")
out.mkdir(parents=True, exist_ok=True)

def run(*a, timeout=45):
    return subprocess.run([adb, "-s", serial, *a], capture_output=True, timeout=timeout)

def dump(n):
    run("shell", "uiautomator", "dump", "/sdcard/oracly_poll.xml")
    p = out / n
    run("pull", "/sdcard/oracly_poll.xml", str(p))
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

def nodes(xml):
    rows = []
    for m in re.finditer(r"<node\b([^>]*)>", xml):
        a = m.group(1)
        def g(n, a=a):
            mm = re.search(rf'{n}="([^"]*)"', a)
            return mm.group(1) if mm else ""
        lab = (g("text") or g("content-desc")).replace("&#10;", "\n").strip()
        if lab:
            rows.append({"c": g("clickable") == "true", "l": lab, "b": g("bounds")})
    return rows

def center(b):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", b)
    return (int(m[1]) + int(m[3])) // 2, (int(m[2]) + int(m[4])) // 2

def y1(b):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", b)
    return int(m[2])

def blob(rows):
    return " || ".join(r["l"].replace("\n", " / ") for r in rows)

def tap_pred(rows, pred, note):
    for r in rows:
        if r["c"] and pred(r["l"]):
            x, y = center(r["b"])
            print("TAP", note, r["l"][:70].replace("\n", " / "), x, y, flush=True)
            run("shell", "input", "tap", str(x), str(y))
            return True
    return False

run("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(2.0)
rows = nodes(dump("z0.xml"))
# Prefer bottom-nav Yıldızname (y > 1350)
tabbed = False
for r in rows:
    if r["c"] and r["l"].strip() == "Yıldızname" and y1(r["b"]) > 1350:
        x, y = center(r["b"])
        print("TAP bottom-tab", x, y, flush=True)
        run("shell", "input", "tap", str(x), str(y))
        tabbed = True
        break
if not tabbed:
    tap_pred(rows, lambda l: l.strip() == "Yıldızname", "any-yildiz")
time.sleep(2.2)
rows = nodes(dump("z_hub.xml"))
hub = blob(rows)
print("HUB", hub[:900], flush=True)
for _ in range(3):
    run("shell", "input", "swipe", "360", "1200", "360", "480", "320")
    time.sleep(0.35)
rows = nodes(dump("z_scroll.xml"))
scrolled = blob(rows)
print("SCROLL", scrolled[:900], flush=True)
leaf = tap_pred(rows, lambda l: ("Doğum" in l) or ("yapra" in l.lower()) or ("iplik" in l.lower()) or ("Geleneksel" in l), "door")
time.sleep(1.6)
rows = nodes(dump("z_door.xml"))
door = blob(rows)
print("DOOR", door[:700], flush=True)
log = run("logcat", "-d", "-t", "40").stdout.decode("utf-8", "replace")
crash = any(x in log for x in ("FATAL EXCEPTION", "FlutterError", "RenderFlex overflowed"))
ok_hub = "YILDIZNAME" in hub.upper() or "Arşiv" in hub or "yapra" in hub.lower() or "Doğum" in hub
report = {
    "DEVICE_VERIFICATION": "PARTIAL" if ok_hub else "FAIL",
    "opened_chamber": ok_hub,
    "hub_sample": hub[:320],
    "scrolled_sample": scrolled[:320],
    "opened_door": leaf,
    "door_sample": door[:280],
    "crash_or_overflow_log": crash,
    "province_picker": "Birth Chart nested path — not exercised this smoke",
    "or_save_journal": False,
    "redeployed": False,
}
(out / "YILDIZNAME22_SMOKE.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2))
