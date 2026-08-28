# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_coffee_gate")
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

run("logcat", "-c")
run("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(2)
rows = nodes(dump("c0.xml"))
tap_pred(rows, lambda l: l == "Ana Sayfa", "home")
time.sleep(0.8)
# scroll discovery into view if needed
for _ in range(2):
    run("shell", "input", "swipe", "360", "1100", "360", "500", "350")
    time.sleep(0.4)
rows = nodes(dump("c1.xml"))
print("HOME", blob(rows)[:280], flush=True)
tap_pred(rows, lambda l: "Kahve" in l and ("Fal" in l or "\n" in l or "Fincan" in l), "coffee")
time.sleep(2)
rows = nodes(dump("c_entry.xml"))
b = blob(rows)
print("ENTRY", b[:500], flush=True)
report = {
    "reached_coffee": "Kahve" in b or "KAHVE" in b or "Fincan" in b,
    "capability_note": "bağlantı" in b.lower() or "connection" in b.lower() or "OR" in b,
    "has_camera_cta": "çek" in b.lower() or "FOTO" in b or "Kamera" in b or "photo" in b.lower(),
    "has_gallery": "GALER" in b.upper() or "Galeri" in b,
    "blob": b[:700],
}
# Try gallery path only (no fake photo analysis)
tap_pred(rows, lambda l: "GALER" in l.upper() or "Galeri" in l, "gallery")
time.sleep(1.5)
# May open system picker — back out
run("shell", "input", "keyevent", "4")
time.sleep(1)
rows = nodes(dump("c_after_gallery.xml"))
report["after_gallery"] = blob(rows)[:300]
logs = run("logcat", "-d", "*:S", "flutter:E", "AndroidRuntime:E").stdout.decode("utf-8", "replace")
report["fatal"] = "FATAL EXCEPTION" in logs
report["overflow"] = "OVERFLOWED" in logs or "overflowed by" in logs
report["DEVICE_VERIFICATION"] = "PARTIAL_ENTRY_ONLY"
# Provider cannot be claimed PASS without real cup photo + network analysis
report["provider_stage"] = "NOT_VERIFIED_ON_DEVICE"
out.joinpath("COFFEE20_SMOKE.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)