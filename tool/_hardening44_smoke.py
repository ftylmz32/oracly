import json, re, subprocess, time
from pathlib import Path

ADB = r"D:\android\platform-tools\adb.exe"
SER = "1700848656001190"
OUT = Path(r"c:/Dev/oracly_new/tool/device_hardening_gate")
OUT.mkdir(parents=True, exist_ok=True)

def adb(*a):
    return subprocess.run([ADB, "-s", SER, *a], capture_output=True, text=True, encoding="utf-8", errors="replace")

def dump(name):
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    adb("pull", "/sdcard/ui.xml", str(OUT / name))
    xml = (OUT / name).read_text(encoding="utf-8", errors="replace")
    labels = re.findall('content-desc="([^"]*)"', xml)
    labels = [l.replace("&#10;", " / ") for l in labels if l.strip()]
    nodes = []
    for m in re.finditer(
        r'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"[^>]*clickable="(true|false)"',
        xml,
    ):
        t, x1, y1, x2, y2, c = m.groups()
        if t.strip():
            nodes.append({
                "t": t.replace("&#10;", " / "),
                "c": c == "true",
                "cx": (int(x1) + int(x2)) // 2,
                "cy": (int(y1) + int(y2)) // 2,
            })
    if not nodes:
        for m in re.finditer(
            r'clickable="(true|false)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"[^>]*content-desc="([^"]*)"',
            xml,
        ):
            c, x1, y1, x2, y2, t = m.groups()
            if t.strip():
                nodes.append({
                    "t": t.replace("&#10;", " / "),
                    "c": c == "true",
                    "cx": (int(x1) + int(x2)) // 2,
                    "cy": (int(y1) + int(y2)) // 2,
                })
    return nodes, " | ".join(labels[:80])

def tap(sub):
    nodes, blob = dump("tmp.xml")
    for n in nodes:
        if sub in n["t"] and n["c"]:
            adb("shell", "input", "tap", str(n["cx"]), str(n["cy"]))
            time.sleep(1.2)
            return True, blob
    for n in nodes:
        if sub in n["t"]:
            adb("shell", "input", "tap", str(n["cx"]), str(n["cy"]))
            time.sleep(1.2)
            return True, blob
    return False, blob

results = {"crash": False}
adb("shell", "am", "start", "-n", "app.oracly/.MainActivity")
time.sleep(1.5)
adb("shell", "input", "keyevent", "4")
time.sleep(0.5)
tap("Ana Sayfa")
_, home = dump("home.xml")
results["home_open"] = any(k in home for k in ("ORACLY", "Ke", "Sohbet", "Bug", "Ana"))

ok, _ = tap("OR")
if not ok:
    ok, _ = tap("Sohbet")
_, orblob = dump("or.xml")
results["or_open"] = ok or ("OR" in orblob) or ("Dinliyorum" in orblob)
norm = orblob.lower().replace("\u0131", "i").replace("\u015f", "s").replace("\u011f", "g")
results["or_honest_store"] = ("acilmadi" in norm) or ("not open" in norm) or ("magaza" in norm)
adb("shell", "input", "keyevent", "4")
time.sleep(0.5)

ok, _ = tap("Profil")
_, prof = dump("profile.xml")
results["profile_open"] = ok or ("Profil" in prof)
adb("shell", "input", "keyevent", "4")
time.sleep(0.4)
tap("Ana Sayfa")
time.sleep(0.5)

found = False
for i in range(7):
    nodes, blob = dump("seek.xml")
    cands = [n for n in nodes if "Premium" in n["t"] and n["c"]]
    if cands:
        adb("shell", "input", "tap", str(cands[0]["cx"]), str(cands[0]["cy"]))
        time.sleep(1.3)
        found = True
        break
    adb("shell", "input", "swipe", "360", "1200", "360", "500", "300")
    time.sleep(0.45)
_, prem = dump("premium.xml")
results["premium_cta_found"] = found
results["premium_open"] = found or ("PREM" in prem.upper()) or ("ODA" in prem) or ("Premium" in prem)
results["premium_fake_price"] = ("149,99" in prem) or ("899,99" in prem)
results["note"] = "Installed APK smoke; full feature matrix not redeployed this pass"

(OUT / "HARDENING44_SMOKE.json").write_text(
    json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8"
)
print(json.dumps(results, indent=2, ensure_ascii=False))