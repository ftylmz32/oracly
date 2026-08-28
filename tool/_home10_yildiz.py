# -*- coding: utf-8 -*-
import re, subprocess, time, sys
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

def blob(rows):
    return " || ".join(r["l"].replace("\n"," / ") for r in rows)

run("shell","am","start","-n","app.oracly/.MainActivity"); time.sleep(1)
rows=nodes(dump("y0.xml"))
for r in rows:
    if r["l"]=="Ana Sayfa":
        x,y=center(r["b"]); run("shell","input","tap",str(x),str(y)); break
time.sleep(0.8)
# scroll once so tile clear
run("shell","input","swipe","360","1150","360","500","400"); time.sleep(0.7)
rows=nodes(dump("y1.xml"))
# discovery tile: clickable containing Yıldız and arşiv/arsiv
hit=None
for r in rows:
    if r["c"] and "Yıldızname" in r["l"] and ("arşiv" in r["l"] or "arsiv" in r["l"] or "Yıldız" in r["l"]):
        # prefer longer label (tile not bottom tab)
        if "\n" in r["l"] or "ar" in r["l"]:
            hit=r; break
if not hit:
    for r in rows:
        if r["c"] and r["l"].startswith("Yıldızname") and r["l"]!="Yıldızname":
            hit=r; break
print("HIT", hit, flush=True)
if hit:
    x,y=center(hit["b"]); print("tap",x,y, flush=True)
    run("shell","input","tap",str(x),str(y)); time.sleep(1.6)
after=blob(nodes(dump("y_after.xml")))
print("AFTER", after[:400], flush=True)
# also bottom nav tab from home
for r in nodes(dump("y2.xml")):
    if r["c"] and r["l"]=="Geri":
        x,y=center(r["b"]); run("shell","input","tap",str(x),str(y)); time.sleep(0.8); break
for r in nodes(dump("y3.xml")):
    if r["l"]=="Ana Sayfa":
        x,y=center(r["b"]); run("shell","input","tap",str(x),str(y)); time.sleep(0.8); break
rows=nodes(dump("y4.xml"))
for r in rows:
    if r["c"] and r["l"]=="Yıldızname":
        x,y=center(r["b"]); print("TAB tap",x,y, flush=True)
        run("shell","input","tap",str(x),str(y)); time.sleep(1.4); break
print("TAB AFTER", blob(nodes(dump("y_tab.xml")))[:400], flush=True)