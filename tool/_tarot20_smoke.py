# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_tarot_gate")
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
            print("TAP", note, r["l"][:60], x, y, flush=True)
            run("shell", "input", "tap", str(x), str(y))
            return True
    return False

run("logcat", "-c")
run("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(2)
rows = nodes(dump("t0.xml"))
tap_pred(rows, lambda l: l == "Ana Sayfa", "home")
time.sleep(1)
for _ in range(2):
    run("shell", "input", "swipe", "360", "1150", "360", "500", "400")
    time.sleep(0.5)
rows = nodes(dump("t1.xml"))
print("HOME", blob(rows)[:300], flush=True)
tap_pred(rows, lambda l: l.startswith("Tarot"), "tarot_tile")
time.sleep(2.2)
rows = nodes(dump("t_entry.xml"))
b = blob(rows)
print("ENTRY", b[:500], flush=True)
report = {
    "reached_entry": ("TAROT" in b) and ("TEK" in b or "AÇILIM" in b or "soru" in b.lower()),
    "has_1": "TEK" in b,
    "has_3": "ÜÇ" in b or "Üç" in b,
    "has_5": "BEŞ" in b or "Beş" in b,
    "has_7": "YEDİ" in b or "Yedi" in b,
    "blob": b[:800],
}
tap_pred(rows, lambda l: "TEK" in l, "tek")
time.sleep(0.5)
rows = nodes(dump("t_spread.xml"))
tap_pred(rows, lambda l: "AÇILIM" in l or "BAŞLAT" in l, "start")
time.sleep(2.5)
rows = nodes(dump("t_after_start.xml"))
report["after_start"] = blob(rows)[:400]
print("AFTER_START", report["after_start"], flush=True)
logs = run("logcat", "-d", "*:S", "flutter:E", "AndroidRuntime:E").stdout.decode("utf-8", "replace")
report["fatal"] = "FATAL EXCEPTION" in logs
report["param_assert"] = "parametric value" in logs or "outside of the accepted range" in logs
report["overflow"] = "OVERFLOWED" in logs or "overflowed by" in logs
out.joinpath("TAROT20_SMOKE.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)