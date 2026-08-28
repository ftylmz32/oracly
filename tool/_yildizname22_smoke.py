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

devs = run("devices").stdout.decode("utf-8", "replace")
if serial not in devs:
    print(json.dumps({"DEVICE_VERIFICATION": "BLOCKED", "reason": "device missing"}))
    raise SystemExit(0)

run("logcat", "-c")
run("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(2.0)
rows = nodes(dump("y0.xml"))
tap_pred(rows, lambda l: l == "Ana Sayfa", "home")
time.sleep(0.6)
# Tab bar often has Yıldızname
rows = nodes(dump("y1.xml"))
opened = tap_pred(rows, lambda l: "Yıldızname" in l or "YILDIZNAME" in l.upper(), "tab-or-tile")
if not opened:
    for _ in range(3):
        run("shell", "input", "swipe", "360", "1100", "360", "480", "350")
        time.sleep(0.3)
    rows = nodes(dump("y2.xml"))
    opened = tap_pred(rows, lambda l: "Yıldızname" in l, "discovery")
time.sleep(2.0)
rows = nodes(dump("y_hub.xml"))
hub = blob(rows)
print("HUB", hub[:800], flush=True)

# Scroll for menus / birth CTA
for _ in range(3):
    run("shell", "input", "swipe", "360", "1200", "360", "500", "320")
    time.sleep(0.35)
rows = nodes(dump("y_scrolled.xml"))
scrolled = blob(rows)
print("SCROLLED", scrolled[:800], flush=True)

birth = tap_pred(
    rows,
    lambda l: ("Doğum" in l) or ("birth" in l.lower()) or ("Arşiv yapra" in l) or ("yaprağını" in l),
    "birth-or-leaf",
)
time.sleep(1.5)
rows = nodes(dump("y_birth.xml"))
birth_blob = blob(rows)
print("BIRTH", birth_blob[:700], flush=True)

# If city picker path appears
city = tap_pred(rows, lambda l: ("Şehir" in l) or ("İl" in l) or ("City" in l) or ("doğum yeri" in l.lower()), "city-field")
time.sleep(0.8)
rows = nodes(dump("y_city.xml"))
# Search a province if search field exists — type Ankara
if city or "Ankara" in blob(rows) or "Ara" in blob(rows):
    run("shell", "input", "text", "Ankara")
    time.sleep(0.8)
    rows = nodes(dump("y_search.xml"))
    tap_pred(rows, lambda l: "Ankara" in l, "ankara")
    time.sleep(0.8)

# Try open leaf / karmic / story menu
for _ in range(2):
    run("shell", "input", "keyevent", "4")
    time.sleep(0.4)
rows = nodes(dump("y_back_hub.xml"))
for _ in range(2):
    run("shell", "input", "swipe", "360", "1200", "360", "500", "320")
    time.sleep(0.3)
rows = nodes(dump("y_menus.xml"))
opened_story = tap_pred(
    rows,
    lambda l: ("iplik" in l.lower()) or ("yaprağın" in l.lower()) or ("Tema" in l) or ("Hikâye" in l) or ("Hikaye" in l),
    "story-menu",
)
time.sleep(1.5)
rows = nodes(dump("y_result.xml"))
result = blob(rows)
print("RESULT", result[:700], flush=True)

or_t = tap_pred(rows, lambda l: ("OR" in l) or ("sor" in l.lower()) or ("konuş" in l.lower()), "or")
time.sleep(1.0)
rows = nodes(dump("y_or.xml"))
or_blob = blob(rows)

log = run("logcat", "-d", "-t", "80").stdout.decode("utf-8", "replace")
crash = any(x in log for x in ("FATAL EXCEPTION", "FlutterError", "RenderFlex overflowed"))

report = {
    "DEVICE_VERIFICATION": "PARTIAL" if opened else "FAIL",
    "opened_yildizname": opened,
    "hub_title": "YILDIZNAME" in hub.upper() or "Yıldızname" in hub,
    "has_archive_copy": any(x in scrolled for x in ("ARŞİV", "Arşiv", "yapra", "fasıl", "Doğum")),
    "opened_birth_or_leaf": birth,
    "opened_story": opened_story,
    "result_sample": result[:280],
    "or_tapped": or_t,
    "or_sample": or_blob[:240],
    "crash_or_overflow_log": crash,
    "notes": "Installed APK may lag local source; province picker lives under Birth Chart.",
}
(out / "YILDIZNAME22_SMOKE.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2))
