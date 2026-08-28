# -*- coding: utf-8 -*-
from pathlib import Path

# 1) Registry honesty — preview sun-sign reading, not live sky catalog marketing
p = Path(r"c:\Dev\oracly_new\lib\core\modules\oracly_feature_registry.dart")
t = p.read_text(encoding="utf-8")
old = "subtitle: 'Önizleme · burç kataloğu',"
new = "subtitle: 'Önizleme · Güneş burcu okuması',"
if old not in t:
    raise SystemExit("registry subtitle not found")
p.write_text(t.replace(old, new), encoding="utf-8")
print("registry honesty")

# 2) Zodiac tab — soft selected scale + gold edge depth (file may be >150; keep surgical)
p = Path(r"c:\Dev\oracly_new\lib\features\astrology\presentation\reference\astrology_reference_zodiac_tab.dart")
t = p.read_text(encoding="utf-8")
if "Transform.scale" not in t:
    # wrap _well return with AnimatedScale
    needle = """    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: circleSize,
      height: circleSize,"""
    repl = """    final scale = selected ? (_pressed ? 0.96 : 1.04) : (_pressed ? 0.97 : 1.0);
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: circleSize,
      height: circleSize,"""
    if needle not in t:
        raise SystemExit("well block missing")
    t = t.replace(needle, repl, 1)
    # close AnimatedScale — find end of _well method decoration child
    # Look for closing of AnimatedContainer in _well - the return ends before label
    # After the AnimatedContainer's closing paren of decoration child tree...
    # Simpler: find unique end pattern in _well
    close_marker = """      child: ClipOval(
        child: AstrologyZodiacIllustration(
          signId: widget.sign.id,
          size: circleSize,
        ),
      ),
    );"""
    close_repl = """      child: ClipOval(
        child: AstrologyZodiacIllustration(
          signId: widget.sign.id,
          size: circleSize,
        ),
      ),
    ),
    );"""
    if close_marker not in t:
        # print nearby for debug
        idx = t.find("ClipOval")
        print(t[idx:idx+400])
        raise SystemExit("close marker missing")
    t = t.replace(close_marker, close_repl, 1)
    p.write_text(t, encoding="utf-8")
    print("tab motion added")
else:
    print("tab motion already present")