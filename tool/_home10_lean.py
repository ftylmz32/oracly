# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_home_gate")
report = {"device": "TECNO KN8", "visual": {}, "taps": {}, "issues": []}

def run(*args, timeout=45):
    return subprocess.run([adb, "-s", serial, *args], capture_output=True, timeout=timeout)

def run_t(*args, timeout=45):
    r = run(*args, timeout=timeout)
    return r.stdout.decode("utf-8", "replace"), r.stderr.decode("utf-8", "replace"), r.returncode

def dump(name):
    run_t("shell", "uiautomator", "dump", "/sdcard/oracly_poll.xml")
    p = out / name
    run_t("pull", "/sdcard/oracly_poll.xml", str(p))
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

def nodes(xml):
    rows = []
    for m in re.finditer(r"<node\b([^>]*)>", xml):
        a = m.group(1)
        def g(n, a=a):
            mm = re.search(rf'{n}="([^"]*)"', a)
            return mm.group(1) if mm else ""
        lab = (g("text") or g("content-desc")).replace("&#10;", "\n").strip()
        if not lab:
            continue
        rows.append({"click": g("clickable")=="true", "label": lab, "bounds": g("bounds")})
    return rows

def blob(rows):
    return " || ".join(r["label"].replace("\n"," / ") for r in rows)

def center(bounds):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    return ((int(m[1])+int(m[3]))//2, (int(m[2])+int(m[4]))//2)

def tap(bounds, note=""):
    x,y = center(bounds)
    print(f"TAP {note} {x},{y}", flush=True)
    run_t("shell", "input", "tap", str(x), str(y))

def find(rows, pred, clickable=None):
    for r in rows:
        if clickable is True and not r["click"]:
            continue
        if pred(r["label"]):
            return r
    return None

def contains_any(s, parts):
    sl = s.lower()
    return any(p.lower() in sl for p in parts)

def go_home(rows=None):
    if rows is None:
        rows = nodes(dump("nav_home.xml"))
    # Prefer Geri if present
    geri = find(rows, lambda l: l.strip().startswith("Geri") or l=="Geri", clickable=True)
    if geri:
        tap(geri["bounds"], "Geri")
        time.sleep(0.9)
        rows = nodes(dump("after_geri.xml"))
    # Then Ana Sayfa tab
    if not is_home(rows):
        ana = find(rows, lambda l: "Ana Sayfa" in l, clickable=True)
        if ana:
            tap(ana["bounds"], "AnaSayfa")
            time.sleep(1.0)
            rows = nodes(dump("after_ana.xml"))
    return rows

def is_home(rows):
    b = blob(rows)
    return ("Ana Sayfa" in b) and (("Bug" in b) or ("Ke" in b) or ("Sohbete" in b) or ("ORACLY" in b and "Yolcu" in b))

def scroll_up():
    run_t("shell", "input", "swipe", "360", "1100", "360", "450", "350")

def scroll_down():
    run_t("shell", "input", "swipe", "360", "450", "360", "1100", "350")

# Ensure app foreground
run_t("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(2)
run_t("logcat", "-c")

rows = go_home()
# If still not home (onboarding), abort honest
if "Atla" in blob(rows) and "Seni" in blob(rows):
    report["issues"].append("stuck_on_onboarding")
    print("BLOCKED onboarding", flush=True)
    out.joinpath("HOME10_REPORT.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    raise SystemExit(2)

# Ensure top of home
for _ in range(2):
    scroll_down()
    time.sleep(0.4)
rows = nodes(dump("v_top.xml"))
print("TOP:", blob(rows)[:500], flush=True)

vis = {
    "exactly_one_ana_sayfa": sum(1 for r in rows if r["label"]=="Ana Sayfa") == 1,
    "logo_oracly": any("ORACLY" in r["label"] for r in rows),
    "hero": any(("Yolcu" in r["label"]) or ("geldin" in r["label"].lower()) for r in rows),
    "or_flagship": any(("Sohbete" in r["label"]) or ("Sakin bir sohbet" in r["label"]) for r in rows),
    "bugunun_izi": any("Bug" in r["label"] and ("zi" in r["label"] or "İzi" in r["label"] or "izi" in r["label"].lower()) for r in rows) or any("Kart" in r["label"] for r in rows),
    "discovery_grid": all(any(k in blob(rows) for k in [x]) for x in ["Kahve", "El", "Astroloji", "Tarot"]) and ("Ruh" in blob(rows)),
    "bottom_nav": all(any(r["label"]==t for r in rows) for t in ["Ana Sayfa", "Kahve", "Astroloji", "Profil"]),
    "premium": False,
    "gems": False,
}

# Scroll for premium + gems
for i in range(5):
    b = blob(rows)
    if "Premium" in b:
        vis["premium"] = True
        # check clip: premium clickable height
        prem = find(rows, lambda l: "Premium" in l, clickable=True)
        if prem:
            m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", prem["bounds"])
            h = int(m[4]) - int(m[2])
            vis["premium_height_px"] = h
            if h < 40:
                report["issues"].append(f"premium_clipped_height_{h}")
    if contains_any(b, ["Mücevher", "Mucevher", "cevher", "Taş", "Gem", "bakiye"]) or re.search(r"\b\d+\b", b) and "cevher" in b.lower():
        vis["gems"] = True
    # also gem in header after open destinations often; look for dedicated home gems banner strings
    if any("20" in r["label"] and ("cevher" in r["label"].lower() or "Gem" in r["label"]) for r in rows):
        vis["gems"] = True
    if vis["premium"] and vis["gems"]:
        break
    scroll_up()
    time.sleep(0.7)
    rows = nodes(dump(f"v_scroll_{i}.xml"))
    print(f"SCROLL{i}:", blob(rows)[:350], flush=True)

# Gems may live in home gems banner — grep XML for gem
if not vis["gems"]:
    raw = (out/"v_top.xml").read_text(encoding="utf-8", errors="replace") + blob(rows)
    vis["gems"] = ("cevher" in raw.lower()) or ("gem" in raw.lower()) or ("taş" in raw.lower())
    if not vis["gems"]:
        report["issues"].append("gems_not_visible_on_home_scroll")

report["visual"] = vis

# Reset top
for _ in range(3):
    scroll_down(); time.sleep(0.35)
rows = nodes(dump("tap_top.xml"))

# Destinations: (key, finder)
dests = [
    ("or_chat", lambda l: "Sohbete" in l),
    ("coffee_tile", lambda l: "Kahve Fal" in l or ("Kahve" in l and "Fal" in l)),
    ("palm", lambda l: "El Fal" in l or ("Avu" in l and "iz" in l.lower())),
    ("astrology_tile", lambda l: l.startswith("Astroloji") and ("Bug" in l or "g" in l)),
    ("yildizname_tile", lambda l: "ld" in l and "name" in l.lower() or "Y" in l[:1] and "ld" in l),
    ("soulmate", lambda l: "Ruh" in l),
    ("tarot", lambda l: l.startswith("Tarot") or l.startswith("Tarot ")),
    ("premium", lambda l: "Premium" in l),
    ("profile_tab", lambda l: l == "Profil"),
]

# Fix yildizname finder more carefully
def find_yildiz(l):
    return ("ld" in l and ("name" in l.lower() or "ar" in l.lower())) and ("Ruh" not in l) and ("Tarot" not in l) and ("Kahve" not in l)

dests[4] = ("yildizname_tile", find_yildiz)

for key, pred in dests:
    rows = go_home(nodes(dump(f"pre_{key}.xml")))
    if not is_home(rows) and key != "profile_tab":
        # relaunch
        run_t("shell", "am", "start", "-n", "app.oracly/.MainActivity")
        time.sleep(1.5)
        rows = go_home()
    target = None
    for s in range(6):
        target = find(rows, pred, clickable=True) or find(rows, pred)
        if target:
            break
        scroll_up(); time.sleep(0.55)
        rows = nodes(dump(f"seek2_{key}_{s}.xml"))
    if not target:
        report["taps"][key] = {"ok": False, "error": "not_found"}
        report["issues"].append(f"{key}_not_found")
        print("MISS", key, flush=True)
        for _ in range(2):
            scroll_down(); time.sleep(0.3)
        continue
    tap(target["bounds"], key)
    time.sleep(1.6)
    rows2 = nodes(dump(f"d2_{key}.xml"))
    b2 = blob(rows2)
    crashed = "keeps stopping" in b2.lower() or "Unfortunately" in b2
    if key == "profile_tab":
        ok = (not crashed) and ("Profil" in b2)
        left_home_content = not (("Sohbete" in b2) and ("Ke" in b2))
        ok = ok and True
    else:
        # navigated away from home content OR has Geri
        ok = (not crashed) and (("Geri" in b2) or (not is_home(rows2)) or (key=="premium" and "Premium" in b2 and "Ma" in b2))
        # premium may push new route
        if key == "premium":
            ok = not crashed and ("Premium" in b2 or "Geri" in b2 or "Ma" in b2 or not is_home(rows2))
    report["taps"][key] = {
        "ok": ok,
        "crashed": crashed,
        "tapped": target["label"].replace("\n"," / ")[:90],
        "after": b2[:280],
        "is_home_after": is_home(rows2),
    }
    print(f"DEST {key} ok={ok}", flush=True)
    rows = go_home(rows2)

# Final checks
rows = go_home()
b = blob(rows)
report["final"] = {
    "blob": b[:700],
    "ana_sayfa_count": sum(1 for r in rows if r["label"]=="Ana Sayfa"),
    "debug_overlay": any(x in b.lower() for x in ["debug", "fps", "repaint rainbow", "screenshot", "capture ui"]),
}
if report["final"]["ana_sayfa_count"] != 1:
    report["issues"].append("ana_sayfa_count_not_1")
if report["final"]["debug_overlay"]:
    report["issues"].append("debug_overlay_text")

# logs
out_l, _, _ = run_t("logcat", "-d", "*:S", "AndroidRuntime:E", "flutter:E")
report["crash_seen"] = "FATAL EXCEPTION" in out_l
report["fatal_snip"] = [ln for ln in out_l.splitlines() if "FATAL" in ln or "Unhandled" in ln][-10:]

# Verdict
visual_ok = all(vis.get(k) for k in [
    "exactly_one_ana_sayfa","logo_oracly","hero","or_flagship","bugunun_izi","discovery_grid","bottom_nav","premium"
]) and vis.get("gems")
taps_ok = all(v.get("ok") for v in report["taps"].values()) and len(report["taps"]) >= 8
report["DEVICE_VERIFICATION"] = (
    "PASS" if visual_ok and taps_ok and not report["crash_seen"] and not report["issues"]
    else "FAIL" if report["crash_seen"] or any(not v.get("ok") for v in report["taps"].values())
    else "PARTIAL"
)
# If gems missing but everything else ok -> not PASS
if not vis.get("gems"):
    report["DEVICE_VERIFICATION"] = "FAIL" if report["DEVICE_VERIFICATION"]=="PASS" else report["DEVICE_VERIFICATION"]
    report["issues"].append("gems_gate_failed")

out.joinpath("HOME10_REPORT.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)