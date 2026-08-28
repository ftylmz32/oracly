from pathlib import Path
import json
p = Path(r"C:/Users/FATİH TAHA/.cursor/projects/c-Dev-oracly-new/agent-transcripts/dd62bb95-8611-4db8-a695-92e614c80f25/dd62bb95-8611-4db8-a695-92e614c80f25.jsonl")
for line in reversed(p.read_text(encoding="utf-8", errors="replace").splitlines()):
    if "HOME EXACT REBUILD" not in line:
        continue
    o = json.loads(line)
    c = o.get("message", {}).get("content", [])
    print("parts", len(c) if isinstance(c, list) else type(c))
    if isinstance(c, list):
        for part in c:
            if isinstance(part, dict):
                print("type=", part.get("type"), "keys=", list(part.keys()))
    break
else:
    print("HOME EXACT not found in this transcript")
# also scan all transcripts for recent image parts
root = Path(r"C:/Users/FATİH TAHA/.cursor/projects/c-Dev-oracly-new/agent-transcripts")
for jf in sorted(root.glob("*/*.jsonl"), key=lambda x: x.stat().st_mtime, reverse=True)[:5]:
    print("file", jf.name, jf.stat().st_mtime)