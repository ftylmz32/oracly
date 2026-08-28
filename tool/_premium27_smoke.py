import json, re, subprocess, time
from pathlib import Path

ADB = r"D:\android\platform-tools\adb.exe"
SER = "1700848656001190"
OUT = Path(r"c:/Dev/oracly_new/tool/device_premium_gate")
OUT.mkdir(parents=True, exist_ok=True)

def adb(*a):
    return subprocess.run([ADB, "-s", SER, *a], capture_output=True, text=True, encoding="utf-8", errors="replace")

def dump():
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    adb("pull", "/sdcard/ui.xml", str(OUT / "ui.xml"))
    xml = (OUT / "ui.xml").read_text(encoding="utf-8", errors="replace")
    nodes = []
    for m in re.finditer(r"<node ([^>]*)/?>", xml):
        attrs = m.group(1)
        def g(name):
            mm = re.search(name + r'="([^"]*)"', attrs)
            return mm.group(1) if mm else ""
        label = g("content-desc") or g("text")
        bounds = g("bounds")
        clickable = g("clickable") == "true"
        bm = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
        if not bm or not label.strip():
            continue
        x1, y1, x2, y2 = map(int, bm.groups())
        nodes.append({
            "t": label.replace("&#10;", " / "),
            "c": clickable,
            "cx": (x1 + x2) // 2,
            "cy": (y1 + y2) // 2,
        })
    blob = " || ".join(n["t"] for n in nodes[:120])
    return nodes, blob, xml

def tap_label(substr):
    nodes, blob, _ = dump()
    for n in nodes:
        if substr in n["t"] and n["c"]:
            adb("shell", "input", "tap", str(n["cx"]), str(n["cy"]))
            time.sleep(1.3)
            return True, blob
    return False, blob

adb("shell", "input", "keyevent", "4")
time.sleep(0.8)
tap_label("Ana Sayfa")
time.sleep(1.0)

found = False
for i in range(10):
    nodes, blob, _ = dump()
    (OUT / ("seek_%d.txt" % i)).write_text(blob[:2500], encoding="utf-8")
    cands = [n for n in nodes if "Premium" in n["t"] and n["c"]]
    if cands:
        adb("shell", "input", "tap", str(cands[0]["cx"]), str(cands[0]["cy"]))
        time.sleep(1.5)
        found = True
        break
    adb("shell", "input", "swipe", "360", "1200", "360", "500", "350")
    time.sleep(0.6)

nodes, blob, xml = dump()
(OUT / "after_premium.xml").write_text(xml, encoding="utf-8")
norm = (
    blob.lower()
    .replace("\u0131", "i")
    .replace("\u015f", "s")
    .replace("\u011f", "g")
    .replace("\u00fc", "u")
    .replace("\u00f6", "o")
    .replace("\u00e7", "c")
)
honest = ("not open yet" in norm) or ("acilmadi" in norm) or ("magaza" in norm and "satin" in norm)
fake_price = ("149,99" in blob) or ("899,99" in blob) or ("2499" in blob)
report = {
    "opened": found or ("PREM" in blob.upper()) or ("ODA" in blob),
    "honest_unavailable": honest,
    "fake_price": fake_price,
    "fake_success": ("dogrulandi" in norm) or ("confirmed" in norm),
    "home_found_premium_cta": found,
    "blob_after": blob[:1200],
    "REAL_STORE_PURCHASE": "NOT RUN",
    "store": "BLOCKED - EXTERNAL PLAY BILLING SETUP",
}
(OUT / "PREMIUM27_SMOKE.json").write_text(
    json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8"
)
print(json.dumps({k: report[k] for k in report if k != "blob_after"}, indent=2, ensure_ascii=False))
print("BLOB:", blob[:600])