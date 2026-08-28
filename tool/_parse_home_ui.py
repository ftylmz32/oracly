from pathlib import Path
import re
xml = Path(r"c:\Dev\oracly_new\tool\device_home_gate\home_ui.xml").read_text(encoding="utf-8", errors="replace")
texts = [t for t in re.findall(r'text="([^"]*)"', xml) if t.strip()]
descs = [d for d in re.findall(r'content-desc="([^"]*)"', xml) if d.strip()]
pkgs = sorted(set(re.findall(r'package="([^"]+)"', xml)))
print("PKGS", pkgs)
print("TEXTS:")
for t in texts:
    print(" ", t)
print("DESCS:")
for d in descs:
    print(" ", d[:160])
print("PNG", Path(r"c:\Dev\oracly_new\tool\device_home_gate\home_01.png").stat().st_size)