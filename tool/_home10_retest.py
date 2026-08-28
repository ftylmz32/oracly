# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb=r"D:\android\platform-tools\adb.exe"; serial="1700848656001190"
out=Path(r"c:\Dev\oracly_new\tool\device_home_gate")

def run(*a, timeout=40):
    return subprocess.run([adb,"-s",serial,*a],capture_output=True,timeout=timeout)

def dump(n):
    run("shell","uiautomator","dump","/sdcard/oracly_poll.xml")
    p=out/n; run("pull","/sdcard/oracly_poll.xml",str(p))
    return p.read_text(encoding="utf-8",errors="replace") if p.exists() else ""

def nodes(xml):
    rows=[]
    for m in re.finditer(r"<node\b([^>]*)>", xml):
        a=m.group(1)
        def g(n,a=a):
            mm=re.search(rf'{n}="([^"]*)"',a); return mm.group(1) if mm else ""
        lab=(g("text") or g("content-desc")).replace("&#10;","\n").strip()
        if lab: rows.append({"c":g("clickable")=="true","l":lab,"b":g("bounds")})
    return rows

def center(b):
    m=re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",b)
    return (int(m[1])+int(m[3]))//2,(int(m[2])+int(m[4]))//2

def tap_label(rows, pred, note):
    for r in rows:
        if r["c"] and pred(r["l"]):
            x,y=center(r["b"]); print(f"TAP {note} {r['l'][:50]!r} {r['b']} -> {x},{y}", flush=True)
            run("shell","input","tap",str(x),str(y)); return True
    return False

def blob(rows):
    return " || ".join(r["l"].replace("\n"," / ") for r in rows)

run("shell","am","start","-n","app.oracly/.MainActivity"); time.sleep(1.5)
# Ana Sayfa
rows=nodes(dump("r0.xml")); tap_label(rows, lambda l:l=="Ana Sayfa","home"); time.sleep(0.8)
# Scroll until Tarot fully above nav (y2 < 1430)
for i in range(8):
    rows=nodes(dump(f"r_scroll_{i}.xml"))
    tarot=next((r for r in rows if r["c"] and r["l"].startswith("Tarot")), None)
    prem=next((r for r in rows if r["c"] and "Premium" in r["l"]), None)
    gems=any("cevher" in r["l"].lower() or "Mücevher" in r["l"] for r in rows)
    print(f"i={i} tarot={tarot['b'] if tarot else None} prem={prem['b'] if prem else None} gems={gems}", flush=True)
    if tarot:
        y2=int(re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", tarot["b"])[4])
        if y2 < 1400:
            break
    run("shell","input","swipe","360","1150","360","500","400"); time.sleep(0.6)

results={}
# Tap Yıldızname, Tarot, Ruh, Premium with clear targets
for key, pred in [
    ("yildizname", lambda l: l.startswith("Yıldızname") and "/" in l),
    ("ruh", lambda l: "Ruh" in l),
    ("tarot", lambda l: l.startswith("Tarot")),
    ("premium", lambda l: "Premium" in l),
]:
    rows=nodes(dump(f"before_{key}.xml"))
    # ensure home-ish
    if not any("Keşifler" in r["l"] or "Sohbete" in r["l"] or "Premium" in r["l"] for r in rows):
        tap_label(rows, lambda l:l=="Ana Sayfa","rehome"); time.sleep(0.8)
        for _ in range(3):
            run("shell","input","swipe","360","1150","360","500","350"); time.sleep(0.4)
        rows=nodes(dump(f"before2_{key}.xml"))
    ok_tap=tap_label(rows, pred, key)
    time.sleep(1.5)
    after=blob(nodes(dump(f"after_{key}.xml")))
    results[key]={"tapped":ok_tap,"after":after[:300]}
    print(f"RESULT {key}: {after[:200]!r}", flush=True)
    # back via Geri or Ana Sayfa
    rows2=nodes(dump(f"ret_{key}.xml"))
    if not tap_label(rows2, lambda l:l=="Geri" or l.startswith("Geri"),"geri"):
        tap_label(rows2, lambda l:l=="Ana Sayfa","ana")
    time.sleep(0.9)

# Final scroll for gems after marking first session false? can't without code.
# Check if scrolling past premium shows gems when not first session - currently first session
for i in range(4):
    run("shell","input","swipe","360","1200","360","400","400"); time.sleep(0.5)
rows=nodes(dump("bottom.xml"))
print("BOTTOM:", blob(rows)[:500], flush=True)
results["bottom_blob"]=blob(rows)[:500]
results["gems_at_bottom"]=any("cevher" in r["l"].lower() for r in rows)
out.joinpath("HOME10_ROUTE_RETEST.json").write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding="utf-8")