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
            print("TAP", note, r["l"][:70].replace("\n", " / "), x, y, flush=True)
            run("shell", "input", "tap", str(x), str(y))
            return True
    return False

run("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(1.5)
rows = nodes(dump("b0.xml"))
tap_pred(rows, lambda l: l == "Ana Sayfa", "home")
time.sleep(0.5)
for _ in range(3):
    run("shell", "input", "swipe", "360", "1100", "360", "480", "350")
    time.sleep(0.3)
rows = nodes(dump("b1.xml"))
tap_pred(rows, lambda l: "Astroloji" in l, "astro")
time.sleep(1.8)
for _ in range(4):
    run("shell", "input", "swipe", "360", "1200", "360", "500", "320")
    time.sleep(0.35)
rows = nodes(dump("b_hub_scrolled.xml"))
scrolled = blob(rows)
print("SCROLLED", scrolled[:900], flush=True)
browsed = tap_pred(
    rows,
    lambda l: any(s in l for s in ("Boğa", "Aslan", "Akrep", "Terazi", "Yay", "Başak", "Yengeç")),
    "sign-tab",
)
time.sleep(1.0)
rows = nodes(dump("b_after_sign.xml"))
detail = tap_pred(
    rows,
    lambda l: ("derinlik" in l.lower()) or ("Continue" in l) or ("Günün" in l) or ("depth" in l.lower()),
    "detail",
)
if not detail:
    run("shell", "input", "swipe", "360", "700", "360", "1100", "300")
    time.sleep(0.5)
    rows = nodes(dump("b_retry.xml"))
    print("RETRY", blob(rows)[:600], flush=True)
    detail = tap_pred(
        rows,
        lambda l: ("derinlik" in l.lower()) or ("Continue" in l) or ("Günün" in l),
        "detail2",
    )
time.sleep(1.5)
rows = nodes(dump("b_detail.xml"))
db = blob(rows)
print("DETAIL", db[:900], flush=True)
or_t = tap_pred(
    rows,
    lambda l: ("OR" in l) or ("sor" in l.lower()) or ("konuş" in l.lower()) or ("Ask" in l),
    "or",
)
time.sleep(1.2)
rows = nodes(dump("b_or.xml"))
ob = blob(rows)
print("OR", ob[:500], flush=True)
log = run("logcat", "-d", "-t", "60").stdout.decode("utf-8", "replace")
crash = any(x in log for x in ("FATAL EXCEPTION", "FlutterError", "RenderFlex overflowed"))
report = {
    "DEVICE_VERIFICATION": "PARTIAL",
    "scrolled_hub_has_signs": any(
        s in scrolled for s in ("Boğa", "Aslan", "Terazi", "Yengeç", "Başak", "KOÇ", "Koç")
    ),
    "browsed_sign": browsed,
    "opened_detail": detail,
    "detail_sample": db[:320],
    "or_tapped": or_t,
    "or_sample": ob[:320],
    "crash_or_overflow_log": crash,
    "installed_apk_honesty_note": "Hub lead still shows legacy sky copy until redeploy.",
}
(out / "ASTROLOGY34_SMOKE_DETAIL.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
)
print(json.dumps(report, ensure_ascii=False, indent=2))
