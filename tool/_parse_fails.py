from pathlib import Path
log = Path("tool/_rc_test.txt").read_text(encoding="utf-8", errors="replace")
# extract failing test names
fails = []
for line in log.splitlines():
    if " [E]" in line and ".dart:" in line:
        # e.g. 00:11 +188 ~13 -1: path: name [E]
        if line.strip().endswith("[E]"):
            part = line.split(": ", 1)[-1] if ": " in line else line
            fails.append(part.replace(" [E]", "").strip())
# unique preserving order
seen=set(); out=[]
for f in fails:
    if f not in seen:
        seen.add(f); out.append(f)
print("FAIL_COUNT", len(out))
for f in out:
    print(f)
# totals from last summary line
for line in log.splitlines():
    if "Some tests failed" in line or "All tests passed" in line:
        if line.startswith("0") or line.startswith("1") or line.startswith("2"):
            print("SUMMARY", line)
