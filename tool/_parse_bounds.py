import re
from pathlib import Path
xml = Path(r"c:\Dev\oracly_new\tool\device_home_gate\home_poll.xml").read_text(encoding="utf-8", errors="replace")
# node attrs can be in any order
for m in re.finditer(r"<node\b([^/]*?)/>", xml):
    attrs = m.group(1)
    def get(name):
        mm = re.search(rf'{name}="([^"]*)"', attrs)
        return mm.group(1) if mm else ""
    text, desc, bounds, click = get("text"), get("content-desc"), get("bounds"), get("clickable")
    label = text or desc
    if label.strip():
        print(f"click={click} label={label!r} bounds={bounds}")