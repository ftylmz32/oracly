from pathlib import Path
import re

out = Path(r"c:\Dev\oracly_new\tool\device_home_gate")

def labels(path):
    xml = path.read_text(encoding="utf-8", errors="replace")
    labs = []
    for m in re.finditer(r"<node\b([^>]*)>", xml):
        a = m.group(1)
        def g(n, a=a):
            mm = re.search(rf'{n}="([^"]*)"', a)
            return mm.group(1) if mm else ""
        lab = (g("text") or g("content-desc")).strip().replace("&#10;", " / ")
        if lab:
            labs.append((g("clickable")=="true", lab, g("bounds")))
    return labs

for name in ["home_gate.xml", "home_scroll_0.xml", "home_scroll_3.xml", "home_top.xml", "dest_or_chat.xml", "dest_coffee.xml", "dest_tarot.xml", "pre_premium.xml", "seek_premium_2.xml", "seek_profile_0.xml"]:
    p = out / name
    if not p.exists():
        print("MISSING", name)
        continue
    labs = labels(p)
    print("====", name, "n=", len(labs))
    for c,l,b in labs:
        print(f"  {'CLK' if c else '   '} {l[:90]!r} {b}")