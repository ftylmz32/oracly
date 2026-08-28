# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb=r"D:\android\platform-tools\adb.exe"; serial="1700848656001190"
out=Path(r"c:\Dev\oracly_new\tool\device_soulmate_gate"); out.mkdir(parents=True, exist_ok=True)

def run(*a, timeout=40):
    return subprocess.run([adb,"-s",serial,*a],capture_output=True,timeout=timeout)

def dump(n):
    run("shell","uiautomator","dump","/sdcard/oracly_poll.xml")
    p=out/n; run("pull","/sdcard/oracly_poll.xml",str(p))
    return p.read_text(encoding="utf-8",errors="replace") if p.exists() else ""

def nodes(xml):
    rows=[]
    for m in re.finditer(r"<node\b([^>]*)>",xml):
        a=m.group(1)
        def g(n,a=a):
            mm=re.search(rf'{n}="([^"]*)"',a); return mm.group(1) if mm else ""
        lab=(g("text") or g("content-desc")).replace("&#10;","\n").strip()
        if lab: rows.append({"c":g("clickable")=="true","l":lab,"b":g("bounds")})
    return rows

def center(b):
    m=re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",b)
    return (int(m[1])+int(m[3]))//2,(int(m[2])+int(m[4]))//2

def blob(rows): return " || ".join(r["l"].replace("\n"," / ") for r in rows)

run("shell","am","start","-n","app.oracly/.MainActivity"); time.sleep(2)
rows=nodes(dump("s0.xml"))
# scroll discovery and tap Ruh Eşi tile (not bottom nav - may not exist)
for _ in range(3):
    run("shell","input","swipe","360","1100","360","480","320"); time.sleep(0.3)
rows=nodes(dump("s1.xml"))
opened=False
for r in rows:
    if r["c"] and ("Ruh Eşi" in r["l"] or "Soulmate" in r["l"] or "SOULMATE" in r["l"].upper()):
        x,y=center(r["b"]); print("TAP",r["l"][:50],x,y); run("shell","input","tap",str(x),str(y)); opened=True; break
time.sleep(2.2)
rows=nodes(dump("s_entry.xml")); b=blob(rows)
print("ENTRY",b[:700])
has_premium=("Premium" in b) or ("premium" in b.lower()) or ("üyelik" in b.lower()) or ("abonelik" in b.lower())
has_form=("Doğum" in b) or ("PORTRE" in b.upper()) or ("isim" in b.lower()) or ("İsim" in b)
has_locked=("RUH EŞİ" in b.upper()) or ("Ruh Eşi" in b)
log=run("logcat","-d","-t","40").stdout.decode("utf-8","replace")
crash=any(x in log for x in ("FATAL EXCEPTION","FlutterError","RenderFlex overflowed"))
# live generation requires premium+proxy - mark blocked
report={
 "DEVICE_VERIFICATION":"PARTIAL" if opened else "FAIL",
 "opened_entry":opened,
 "looks_like_chamber":has_locked or has_form or has_premium,
 "has_form_or_premium_gate":has_form or has_premium,
 "live_generation":"BLOCKED",
 "live_generation_reason":"Requires Premium entitlement + deployed AI proxy; not exercised on this smoke.",
 "crash_or_overflow_log":crash,
 "entry_sample":b[:280],
 "redeployed":False,
}
(out/"SOULMATE21_SMOKE.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps(report,ensure_ascii=False,indent=2))
