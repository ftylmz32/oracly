import re, subprocess, time, json
from pathlib import Path

adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_home_gate")
report = {"visual": {}, "taps": {}, "issues": [], "device": "TECNO KN8"}

def run(*args, timeout=90):
    return subprocess.run([adb, "-s", serial, *args], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)

def dump(name):
    run("shell", "uiautomator", "dump", "/sdcard/oracly_poll.xml")
    p = out / name
    run("pull", "/sdcard/oracly_poll.xml", str(p))
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

def shot(name):
    # exec-out often more reliable than pull of empty files
    p = out / name
    with open(p, "wb") as f:
        r = subprocess.run([adb, "-s", serial, "exec-out", "screencap", "-p"], stdout=f, stderr=subprocess.PIPE, timeout=60)
    print("shot", name, "bytes", p.stat().st_size if p.exists() else 0, "rc", r.returncode)

def nodes(xml):
    rows = []
    for m in re.finditer(r"<node\b([^>]*)>", xml):
        a = m.group(1)
        def g(n, a=a):
            mm = re.search(rf'{n}="([^"]*)"', a)
            return mm.group(1) if mm else ""
        text, desc, bounds, click = g("text"), g("content-desc"), g("bounds"), g("clickable")
        label = (text or desc).strip()
        # unescape common entities
        label = label.replace("&#10;", "\n").replace("&amp;", "&")
        if label:
            rows.append({
                "click": click == "true",
                "label": label,
                "bounds": bounds,
                "scroll": g("scrollable") == "true",
                "cls": g("class"),
            })
    return rows

def blob(rows):
    return " || ".join(r["label"].replace("\n", " / ") for r in rows)

def find(rows, *needles, clickable_only=False):
    for r in rows:
        if clickable_only and not r["click"]:
            continue
        lab = r["label"].lower()
        if any(n.lower() in lab for n in needles):
            return r
    return None

def center(bounds):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    x1,y1,x2,y2 = map(int, m.groups())
    return (x1+x2)//2, (y1+y2)//2

def tap_row(r, note=""):
    x,y = center(r["bounds"])
    print(f"TAP {note or r['label'][:40]!r} -> {x},{y}")
    run("shell", "input", "tap", str(x), str(y))

def swipe_up():
    run("shell", "input", "swipe", "360", "1200", "360", "400", "400")

def back():
    run("shell", "input", "keyevent", "4")

def wait_stable(sec=1.2):
    time.sleep(sec)

# Clear logcat for crash detection
run("logcat", "-c")

xml = dump("home_gate.xml")
rows = nodes(xml)
print("HOME_BLOB:\n", blob(rows))
shot("home_gate.png")

# Visual checklist markers
checks = {
    "exactly_one_home": None,
    "logo_oracly": any("ORACLY" in r["label"] for r in rows),
    "hero": any("Hoş" in r["label"] or "Hos" in r["label"] or "Yolcu" in r["label"] or "keşfedelim" in r["label"].lower() or "kesfedelim" in r["label"].lower() for r in rows),
    "or_flagship": any(re.search(r"\bOR\b", r["label"]) and ("Sohbet" in r["label"] or "sohbet" in r["label"].lower()) for r in rows) or any(r["label"].startswith("OR") for r in rows),
    "bugunun_izi": any("Bug" in r["label"] for r in rows),
    "discovery_grid": any(x in blob(rows) for x in ("Kahve", "El", "Tarot", "Yıldız", "Yildiz", "Astroloji", "Göky", "Goky")),
    "premium": False,
    "gems": False,
    "bottom_nav": any("Ana Sayfa" in r["label"] for r in rows) and any("Profil" in r["label"] or "OR" in r["label"] for r in rows),
}

# Count Ana Sayfa selected / home labels
ana = [r for r in rows if "Ana Sayfa" in r["label"]]
checks["exactly_one_home"] = len(ana) == 1
print("ANA_SAYFA_COUNT", len(ana), ana)

# Scroll to reveal Premium / Gems
for i in range(4):
    b = blob(rows)
    if "Premium" in b or "premium" in b.lower():
        checks["premium"] = True
    if any(x in b.lower() for x in ("gem", "taş", "tas", "mücevher", "mucevher", "bakiye")):
        checks["gems"] = True
    if checks["premium"] and checks["gems"]:
        break
    swipe_up()
    wait_stable(0.9)
    xml = dump(f"home_scroll_{i}.xml")
    rows = nodes(xml)
    print(f"SCROLL[{i}]", blob(rows)[:300])

shot("home_scrolled.png")
report["visual"] = checks
report["home_labels"] = [r["label"].replace("\n"," / ")[:100] for r in rows]

# Reset scroll to top for taps
for _ in range(3):
    run("shell", "input", "swipe", "360", "400", "360", "1200", "350")
    wait_stable(0.5)

xml = dump("home_top.xml")
rows = nodes(xml)
print("TOP", blob(rows)[:400])

# Primary destinations to tap
destinations = [
    ("or_chat", ["Sohbete", "Sohbet ba", "OR\nSakin", "Sakin bir sohbet"]),
    ("coffee", ["Kahve"]),
    ("palm", ["El", "Avuç", "Avuc"]),
    ("astrology", ["Göky", "Goky", "Astroloji"]),
    ("yildizname", ["Yıldız", "Yildiz", "Yıldızname", "Yildizname"]),
    ("tarot", ["Tarot"]),
    ("soulmate", ["Ruh", "Soul"]),
    ("premium", ["Premium"]),
    ("profile", ["Profil"]),
]

def is_home(rows):
    b = blob(rows)
    return "Ana Sayfa" in b and ("ORACLY" in b or "Bug" in b or "Ke" in b)

results = {}
for key, needles in destinations:
    # ensure on home
    for attempt in range(3):
        xml = dump(f"pre_{key}.xml")
        rows = nodes(xml)
        if is_home(rows) or key == "profile":
            break
        back()
        wait_stable(0.8)
    # scroll until target visible for premium/gems/soulmate
    target = None
    for s in range(5):
        target = find(rows, *needles, clickable_only=True)
        if target is None:
            target = find(rows, *needles, clickable_only=False)
        if target:
            break
        swipe_up()
        wait_stable(0.7)
        xml = dump(f"seek_{key}_{s}.xml")
        rows = nodes(xml)
    if not target:
        results[key] = {"ok": False, "error": "not_found", "labels_sample": blob(rows)[:200]}
        report["issues"].append(f"{key}: not found")
        # scroll back top
        for _ in range(3):
            run("shell", "input", "swipe", "360", "400", "360", "1200", "300")
        continue
    # if not clickable, tap center anyway
    tap_row(target, key)
    wait_stable(1.8)
    xml2 = dump(f"dest_{key}.xml")
    rows2 = nodes(xml2)
    b2 = blob(rows2)
    still_home = is_home(rows2) and key not in ("profile",)  # profile may keep shell
    # profile is tab - still has Ana Sayfa
    crashed = "Unfortunately" in b2 or "keeps stopping" in b2.lower()
    ok = (not crashed) and (not still_home or key in ("profile",))
    # For profile, expect Profil selected / profile content
    if key == "profile":
        ok = "Profil" in b2 and not crashed
    results[key] = {
        "ok": ok,
        "still_home": still_home,
        "crashed": crashed,
        "after": b2[:240],
        "tapped": target["label"][:80],
    }
    print(f"DEST {key} ok={ok} after={b2[:160]!r}")
    shot(f"dest_{key}.png")
    # return home
    if key == "profile":
        # tap Ana Sayfa
        home_tab = find(rows2, "Ana Sayfa", clickable_only=True) or find(rows2, "Ana Sayfa")
        if home_tab:
            tap_row(home_tab, "home_tab")
            wait_stable(1.0)
    else:
        back()
        wait_stable(1.0)
        # if still not home, tap Ana Sayfa
        xml3 = dump(f"back_{key}.xml")
        rows3 = nodes(xml3)
        if not is_home(rows3):
            home_tab = find(rows3, "Ana Sayfa", clickable_only=True) or find(rows3, "Ana Sayfa")
            if home_tab:
                tap_row(home_tab, "home_tab")
                wait_stable(1.0)
            else:
                back()
                wait_stable(0.8)

report["taps"] = results

# Final home dump for duplicate/debug overlays
xml = dump("home_final_check.xml")
rows = nodes(xml)
b = blob(rows)
report["final_home_blob"] = b[:800]
report["duplicate_home"] = b.lower().count("ana sayfa")
report["debug_overlay"] = any(x in b.lower() for x in ("debug", "fps", "repaint", "performance overlay", "screenshot", "capture", "ekran görünt", "ekran gorunt"))
report["issues"] += []
if report["duplicate_home"] > 1:
    report["issues"].append("duplicate Ana Sayfa labels >1")
if report["debug_overlay"]:
    report["issues"].append("possible debug/capture overlay text")

# Crash logs
logs = run("logcat", "-d", "*:S", "AndroidRuntime:E", "flutter:E")
fatal = [ln for ln in logs.stdout.splitlines() if "FATAL" in ln or "Exception" in ln or "Error" in ln]
report["fatal_log_lines"] = fatal[-20:]
report["crash_seen"] = any("FATAL EXCEPTION" in ln for ln in logs.stdout.splitlines())

# Bottom nav presence at end
report["visual"]["bottom_nav_final"] = "Ana Sayfa" in b

out.joinpath("HOME10_REPORT.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2))