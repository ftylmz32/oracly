# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_astrology_gate")
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
            print("TAP", note, r["l"][:60].replace("\n"," / "), x, y, flush=True)
            run("shell", "input", "tap", str(x), str(y))
            return True
    return False

devs = run("devices").stdout.decode("utf-8", "replace")
if serial not in devs:
    print(json.dumps({"DEVICE_VERIFICATION": "BLOCKED", "reason": "device missing"}))
    raise SystemExit(0)

run("logcat", "-c")
run("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(2.2)
rows = nodes(dump("a0.xml"))
tap_pred(rows, lambda l: l == "Ana Sayfa", "home")
time.sleep(0.8)
for _ in range(3):
    run("shell", "input", "swipe", "360", "1100", "360", "480", "350")
    time.sleep(0.35)
rows = nodes(dump("a1.xml"))
opened = tap_pred(
    rows,
    lambda l: ("Astroloji" in l) or ("ASTROLOJ" in l.upper()) or ("Burç" in l and "Yorum" in l),
    "astrology",
)
time.sleep(2.0)
rows = nodes(dump("a_hub.xml"))
hub = blob(rows)
print("HUB", hub[:700], flush=True)

# Browse another sign if tabs visible
browsed = tap_pred(rows, lambda l: l.strip() in ("Boğa", "Aslan", "Akrep", "Taurus", "Leo"), "sign")
time.sleep(1.0)
rows = nodes(dump("a_sign.xml"))
sign_blob = blob(rows)

# Open detail
detail = tap_pred(
    rows,
    lambda l: ("derinlik" in l.lower()) or ("depth" in l.lower()) or ("Continue" in l) or ("Günün" in l),
    "detail",
)
time.sleep(1.5)
rows = nodes(dump("a_detail.xml"))
detail_blob = blob(rows)

# Look for OR / save affordances
has_or = any(("OR" in r["l"] or "or" in r["l"].lower() or "Soru" in r["l"] or "Ask" in r["l"] or "sor" in r["l"].lower()) for r in rows)
has_save = any(("Kaydet" in r["l"] or "Favori" in r["l"] or "Save" in r["l"] or "anı" in r["l"].lower()) for r in rows)

# Attempt OR tap if present
or_tapped = tap_pred(
    rows,
    lambda l: ("OR" in l and len(l) < 40) or ("Sor" in l) or ("Ask" in l) or ("konuş" in l.lower()),
    "or",
)
time.sleep(1.2)
rows = nodes(dump("a_or.xml"))
or_blob = blob(rows)

log = run("logcat", "-d", "-t", "80").stdout.decode("utf-8", "replace")
crash = any(x in log for x in ("FATAL EXCEPTION", "FlutterError", "RenderFlex overflowed"))

report = {
    "DEVICE_VERIFICATION": "PARTIAL" if opened else "FAIL",
    "opened_astrology": opened,
    "hub_has_title": ("ASTROLOJ" in hub.upper()) or ("Astroloji" in hub),
    "hub_has_sign": any(s in hub for s in ("Koç", "Boğa", "Aslan", "Aries", "Taurus")),
    "browsed_sign": browsed,
    "opened_detail": detail,
    "detail_has_report": any(x in detail_blob for x in ("GÖZLEM", "GÜN", "Tema", "ÖZEL", "ANLAMA", "YANSIMA", "derinlik", "Derinlik")),
    "has_or_affordance": has_or,
    "has_save_affordance": has_save,
    "or_tapped": or_tapped,
    "or_context_hint": ("Astroloji" in or_blob) or ("burç" in or_blob.lower()) or ("Koç" in or_blob) or ("anlatmana" in or_blob),
    "crash_or_overflow_log": crash,
    "notes": "Smoke on installed APK; may lag behind local source until redeploy.",
}
(out / "ASTROLOGY34_SMOKE.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2))
