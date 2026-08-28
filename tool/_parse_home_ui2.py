from pathlib import Path
import re
xml = Path(r"c:\Dev\oracly_new\tool\device_home_gate\home_ui2.xml").read_text(encoding="utf-8", errors="replace")
texts = [t for t in re.findall(r'text="([^"]*)"', xml) if t.strip()]
descs = [d for d in re.findall(r'content-desc="([^"]*)"', xml) if d.strip()]
print("TEXTS:")
for t in texts: print(" ", t)
print("DESCS:")
for d in descs: print(" ", d[:200])
print("PNG2", Path(r"c:\Dev\oracly_new\tool\device_home_gate\home_02.png").stat().st_size)