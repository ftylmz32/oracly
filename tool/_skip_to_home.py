import re, subprocess, time
from pathlib import Path

adb = r"D:\android\platform-tools\adb.exe"
serial = "1700848656001190"
out = Path(r"c:\Dev\oracly_new\tool\device_home_gate")

def run(*args, timeout=60):
    return subprocess.run([adb, "-s", serial, *args], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)

def dump(name):
    run("shell", "uiautomator", "dump", "/sdcard/oracly_poll.xml")
    run("pull", "/sdcard/oracly_poll.xml", str(out / name))
    p = out / name
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

def nodes(xml):
    rows = []
    for m in re.finditer(r"<node\b([^>]*)>", xml):
        attrs = m.group(1)
        def get(n):
            mm = re.search(rf'{n}="([^"]*)"', attrs)
            return mm.group(1) if mm else ""
        text, desc, bounds, click = get("text"), get("content-desc"), get("bounds"), get("clickable")
        label = (text or desc).strip()
        if label:
            rows.append((click == "true", label, bounds))
    return rows

def tap_label(xml, *needles):
    for click, label, bounds in nodes(xml):
        if not click:
            continue
        if any(n.lower() in label.lower() for n in needles):
            m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
            if not m:
                continue
            x1,y1,x2,y2 = map(int, m.groups())
            x, y = (x1+x2)//2, (y1+y2)//2
            # Prefer right side for full-width Atla chrome
            if "Atla" in label and (x2-x1) > 400:
                x = x2 - 80
                y = (y1+y2)//2
            print(f"TAP {label!r} at {x},{y}")
            run("shell", "input", "tap", str(x), str(y))
            return True
    return False

def blob(xml):
    return " | ".join(l for _, l, _ in nodes(xml))

# Skip onboarding
xml = dump("step_onboard.xml")
print("BEFORE", blob(xml)[:300])
if not tap_label(xml, "Atla", "Skip"):
    # fallback tap top-right
    print("fallback top-right tap")
    run("shell", "input", "tap", "650", "115")

time.sleep(2)

home_markers = ["Bug", "Ke", "OR ile", "Sohbet", "Premium", "Ana Sayfa", "Gems", "Ta"]
for i in range(20):
    xml = dump("step_home.xml")
    b = blob(xml)
    print(f"[{i}] {b[:220]!r}")
    # still onboarding?
    if "Atla" in b or "tan" in b.lower() and "Seni" in b:
        tap_label(xml, "Atla", "Skip")
        time.sleep(1.5)
        continue
    hits = sum(1 for m in ["Bug", "Ana Sayfa", "ORACLY", "Premium", "Kahve", "Sohbet"] if m in b)
    # True home often has bottom nav Ana Sayfa
    if "Ana Sayfa" in b or ("Bug" in b and "Ke" in b):
        run("shell", "screencap", "-p", "/sdcard/oracly_home_final.png")
        run("pull", "/sdcard/oracly_home_final.png", str(out / "home_final.png"))
        print("REACHED_HOME")
        print("ALL_LABELS:")
        for click, label, bounds in nodes(xml):
            print(f"  click={click} {label[:80]!r} {bounds}")
        break
    time.sleep(2)
else:
    print("HOME_NOT_REACHED")
    run("shell", "screencap", "-p", "/sdcard/oracly_home_final.png")
    run("pull", "/sdcard/oracly_home_final.png", str(out / "home_final.png"))

# logcat flutter errors
logs = run("logcat", "-d", "*:S", "flutter:V", "AndroidRuntime:E")
print("---FLUTTER---")
print("\n".join(logs.stdout.splitlines()[-50:]))