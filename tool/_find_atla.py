import re
from pathlib import Path
xml = Path(r"c:\Dev\oracly_new\tool\device_home_gate\home_poll.xml").read_text(encoding="utf-8", errors="replace")
# all nodes including nested with closing tags
for m in re.finditer(r"<node\b([^>]*)>", xml):
    attrs = m.group(1)
    def get(name):
        mm = re.search(rf'{name}="([^"]*)"', attrs)
        return mm.group(1) if mm else ""
    text, desc, bounds, click = get("text"), get("content-desc"), get("bounds"), get("clickable")
    label = (text or desc).strip()
    if "Atla" in label or click == "true" or "Skip" in label:
        print(f"click={click} text={text!r} desc={desc!r} bounds={bounds}")
print("--- raw Atla context ---")
idx = xml.find("Atla")
print(xml[max(0,idx-200):idx+200] if idx>=0 else "no Atla")