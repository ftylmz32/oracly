# -*- coding: utf-8 -*-
import re, subprocess, time, json, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
adb=r"D:\android\platform-tools\adb.exe"; serial="1700848656001190"
out=Path(r"c:\Dev\oracly_new\tool\device_profile_journal_gate"); out.mkdir(parents=True, exist_ok=True)

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

def tap_pred(rows, pred, note):
    for r in rows:
        if r["c"] and pred(r["l"]):
            x,y=center(r["b"]); print("TAP",note,r["l"][:50],x,y); run("shell","input","tap",str(x),str(y)); return True
    return False

run("logcat","-c")
run("shell","am","start","-n","app.oracly/.MainActivity"); time.sleep(2)
rows=nodes(dump("p0.xml"))
# bottom Profil tab
opened=False
for r in rows:
    if r["c"] and r["l"].strip()=="Profil":
        x,y=center(r["b"])
        # prefer bottom
        if int(re.match(r"\[(\d+),(\d+)\]",r["b"]).group(2))>1200 or True:
            print("TAP profil",x,y); run("shell","input","tap",str(x),str(y)); opened=True; break
time.sleep(2)
rows=nodes(dump("p_profile.xml")); pb=blob(rows)
print("PROFILE",pb[:800])
# open journal
for _ in range(2):
    run("shell","input","swipe","360","1200","360","500","300"); time.sleep(0.3)
rows=nodes(dump("p_scroll.xml"))
tap_pred(rows, lambda l: "Keşif" in l or "Günlük" in l or "Journal" in l or "günlük" in l.lower(),"journal")
time.sleep(1.8)
rows=nodes(dump("p_journal.xml")); jb=blob(rows)
print("JOURNAL",jb[:700])
# try open an entry if any
tap_pred(rows, lambda l: any(k in l for k in ("Tarot","Kahve","El","Astroloji","Yıldız","OR","Rüya","Kart")),"entry")
time.sleep(1.5)
rows=nodes(dump("p_entry.xml")); eb=blob(rows)
print("ENTRY",eb[:500])
log=run("logcat","-d","-t","50").stdout.decode("utf-8","replace")
crash=any(x in log for x in ("FATAL EXCEPTION","FlutterError","RenderFlex overflowed"))
report={
 "DEVICE_VERIFICATION":"PARTIAL" if opened else "FAIL",
 "opened_profile":opened,
 "profile_has_personal_copy": any(x in pb for x in ("oda","ORACLY","Keşif","Profil","PROFIL")),
 "opened_journal_attempt": "Keşif" in jb or "GÜNLÜK" in jb.upper() or "Journal" in jb or "günlük" in jb.lower() or "keşif" in jb.lower(),
 "journal_sample": jb[:280],
 "entry_opened_sample": eb[:200],
 "or_delete_verified": False,
 "crash_or_overflow_log": crash,
 "redeployed": False,
 "notes": "Installed APK may lag local source; delete not exercised.",
}
(out/"PROFILE14_SMOKE.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps(report,ensure_ascii=False,indent=2))
