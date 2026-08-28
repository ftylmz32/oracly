# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

adb=r"D:\android\platform-tools\adb.exe"; serial="1700848656001190"
out=Path(r"c:\Dev\oracly_new\tool\device_home_gate")

def run(*a, timeout=40):
    return subprocess.run([adb,"-s",serial,*a],capture_output=True,timeout=timeout)

def dump(name):
    run("shell","uiautomator","dump","/sdcard/oracly_poll.xml")
    p=out/name; run("pull","/sdcard/oracly_poll.xml",str(p))
    return p.read_text(encoding="utf-8",errors="replace") if p.exists() else ""

def nodes(xml):
    rows=[]
    for m in re.finditer(r"<node\b([^>]*)>", xml):
        a=m.group(1)
        def g(n,a=a):
            mm=re.search(rf'{n}="([^"]*)"',a); return mm.group(1) if mm else ""
        lab=(g("text") or g("content-desc")).replace("&#10;","\n").strip()
        if lab:
            rows.append((g("clickable")=="true", lab, g("bounds")))
    return rows

def parse_b(b):
    m=re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",b)
    return tuple(map(int,m.groups()))

def overlap(a,b):
    ax1,ay1,ax2,ay2=a; bx1,by1,bx2,by2=b
    ix1,iy1=max(ax1,bx1),max(ay1,by1)
    ix2,iy2=min(ax2,bx2),min(ay2,by2)
    if ix2<=ix1 or iy2<=iy1: return 0
    return (ix2-ix1)*(iy2-iy1)

run("shell","am","start","-n","app.oracly/.MainActivity")
time.sleep(2)
# tap Ana Sayfa
xml=dump("overlap_home.xml")
rows=nodes(xml)
for c,l,b in rows:
    if l=="Ana Sayfa":
        x1,y1,x2,y2=parse_b(b); run("shell","input","tap",str((x1+x2)//2),str((y1+y2)//2)); break
time.sleep(1)
xml=dump("overlap_check.xml")
rows=nodes(xml)
print("SCREEN_NODES:")
nav=[]; tiles=[]
for c,l,b in rows:
    print(("CLK" if c else "   "), l.replace("\n"," / ")[:80], b)
    if l in ("Ana Sayfa","Kahve","Astroloji","Yıldızname","Profil") or l.startswith("Yildiz"):
        nav.append((l,parse_b(b)))
    if any(k in l for k in ("Yıldızname /","Ruh Eşi","Tarot /","Kahve Falı /","El Falı /","Astroloji /")):
        tiles.append((l.split("\n")[0][:40], parse_b(b)))

print("\nOVERLAPS tile vs bottom nav:")
issues=[]
for tl,tb in tiles:
    for nl,nb in nav:
        o=overlap(tb,nb)
        if o>0:
            print(f"  OVERLAP {o}px2  {tl!r} {tb}  vs  {nl} {nb}")
            issues.append({"tile":tl,"nav":nl,"overlap_px2":o,"tile_bounds":tb,"nav_bounds":nb})

# Check gem in header semantics
gem_hits=[(c,l,b) for c,l,b in rows if "cevher" in l.lower() or "gem" in l.lower() or re.search(r"\b\d+\b",l) and "ORACLY" not in l]
print("\nGEM_LIKE:", gem_hits)

# Screenshot via exec-out
p=out/"overlap_home.png"
with open(p,"wb") as f:
    r=subprocess.run([adb,"-s",serial,"exec-out","screencap","-p"],stdout=f,stderr=subprocess.PIPE,timeout=30)
print("shot", p.stat().st_size, "rc", r.returncode)

out.joinpath("HOME10_OVERLAP.json").write_text(json.dumps({"issues":issues,"gem_like":[(c,l,b) for c,l,b in gem_hits]},ensure_ascii=False,indent=2),encoding="utf-8")