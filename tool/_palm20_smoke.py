# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_palm_gate")
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
            print("TAP", note, r["l"][:50], x, y, flush=True)
            run("shell", "input", "tap", str(x), str(y))
            return True
    return False

devs = run("devices").stdout.decode("utf-8", "replace")
if serial not in devs:
    print(json.dumps({"DEVICE_VERIFICATION": "BLOCKED", "reason": "device missing"}))
    raise SystemExit(0)

run("logcat", "-c")
run("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(2)
rows = nodes(dump("p0.xml"))
tap_pred(rows, lambda l: l == "Ana Sayfa", "home")
time.sleep(0.8)
for _ in range(2):
    run("shell", "input", "swipe", "360", "1100", "360", "500", "350")
    time.sleep(0.4)
rows = nodes(dump("p1.xml"))
tap_pred(rows, lambda l: "El Fal" in l or (l.startswith("El") and "\n" in l), "palm")
time.sleep(2)
rows = nodes(dump("p_entry.xml"))
b = blob(rows)
print("ENTRY", b[:500], flush=True)
# Select left hand if visible
tap_pred(rows, lambda l: "Sol" in l or "SOL" in l or "Left" in l, "left")
time.sleep(0.6)
rows = nodes(dump("p_hand.xml"))
tap_pred(rows, lambda l: "FOTO" in l.upper() or "çek" in l.lower() or "Kamera" in l, "camera")
time.sleep(1.5)
# If permission/chamber, back out
run("shell", "input", "keyevent", "4")
time.sleep(0.8)
rows = nodes(dump("p_after.xml"))
report = {
    "reached_palm": "El" in b or "EL" in b or "Avuç" in b or "avuc" in b.lower(),
    "capability_note": "bağlantı" in b.lower() or "OR" in b,
    "has_hand_choice": "Sol" in b or "Sağ" in b or "SOL" in b or "SAĞ" in b or "Left" in blob(rows) or "Right" in blob(rows),
    "has_camera": "FOTO" in b.upper() or "çek" in b.lower(),
    "has_gallery": "GALER" in b.upper(),
    "entry_blob": b[:700],
    "after": blob(rows)[:400],
}
logs = run("logcat", "-d", "*:S", "flutter:E", "AndroidRuntime:E").stdout.decode("utf-8", "replace")
report["fatal"] = "FATAL EXCEPTION" in logs
report["overflow"] = "OVERFLOWED" in logs or "overflowed by" in logs
report["DEVICE_VERIFICATION"] = "PARTIAL_ENTRY_ONLY"
report["provider_stage"] = "BLOCKED" if ("bağlantı" in b.lower() or "connection" in b.lower()) else "NOT_VERIFIED"
out.joinpath("PALM20_SMOKE.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)