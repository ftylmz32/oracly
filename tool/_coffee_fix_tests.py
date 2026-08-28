from pathlib import Path

# OR: keep compact love + near clips
p = Path(r"c:\Dev\oracly_new\lib\features\ai\oracle_conversation\models\oracle_reading_context_sources.dart")
t = p.read_text(encoding="utf-8")
old = """    final full = [
      if (reading.visualObservation.trim().isNotEmpty)
        'Görülen: ${clip(reading.visualObservation, 160)}',
      if (reading.overall.trim().isNotEmpty) 'Genel: ${clip(reading.overall, 280)}',
      if (symbols.isNotEmpty) 'İzler: ${symbols.join(', ')}',
      if (reading.takeaway.trim().isNotEmpty) 'Dikkat: ${clip(reading.takeaway, 160)}',
    ].where((e) => e.trim().isNotEmpty).join('\\n\\n');"""
new = """    final full = [
      if (reading.visualObservation.trim().isNotEmpty)
        'Görülen: ${clip(reading.visualObservation, 160)}',
      if (reading.overall.trim().isNotEmpty) 'Genel: ${clip(reading.overall, 280)}',
      if (symbols.isNotEmpty) 'İzler: ${symbols.join(', ')}',
      if (reading.love.trim().isNotEmpty) 'Aşk: ${clip(reading.love, 140)}',
      if (reading.nearFuture.trim().isNotEmpty)
        'Yön: ${clip(reading.nearFuture, 140)}',
      if (reading.takeaway.trim().isNotEmpty) 'Dikkat: ${clip(reading.takeaway, 160)}',
    ].where((e) => e.trim().isNotEmpty).join('\\n\\n');"""
if old not in t:
    raise SystemExit("or full block missing")
p.write_text(t.replace(old, new), encoding="utf-8")
print("OR lanes restored compact")

# Tests
p = Path(r"c:\Dev\oracly_new\test\features\coffee\coffee_polish_v1_test.dart")
t = p.read_text(encoding="utf-8")
t2 = t.replace(
    "expect(CoffeeCopy.analyzingSubtitle, 'Acele yok.');",
    "expect(CoffeeCopy.analyzingSubtitle, contains('fotoğraf'));",
)
# also source note if asserted
t2 = t2.replace(
    "OR görüntü yorumu",
    "Fincan fotoğrafına bakıldı",
)
p.write_text(t2, encoding="utf-8")
print("polish test updated")

p = Path(r"c:\Dev\oracly_new\test\coffee_honesty_p0_test.dart")
t = p.read_text(encoding="utf-8")
t2 = t.replace("contains('KAHVE')", "contains('Kahve Falı')")
t2 = t2.replace("expect(find.text('KAHVE'), findsOneWidget);", "expect(find.text('Kahve Falı'), findsOneWidget);")
# TAROT might also be Tarot now
if "find.text('TAROT')" in t2:
    # leave TAROT if still used; discovery may say Tarot
    pass
p.write_text(t2, encoding="utf-8")
print("honesty home titles updated")