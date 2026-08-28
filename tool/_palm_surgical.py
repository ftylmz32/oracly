# -*- coding: utf-8 -*-
from pathlib import Path

# 1) Landing camera → chamber path
p = Path(r"c:\Dev\oracly_new\lib\features\palm\presentation\palm_reference_body.dart")
t = p.read_text(encoding="utf-8")
old = """      onCamera: () async {
        controller.startCapture();
        await controller.pickCamera();
      },"""
new = """      onCamera: () {
        // Chamber capture lives on PalmCaptureView — avoid OS picker dual path.
        controller.startCapture();
      },"""
assert old in t, "landing camera block missing"
p.write_text(t.replace(old, new), encoding="utf-8")
print("01 landing chamber")

# 2) Honest source + analyzing hint
p = Path(r"c:\Dev\oracly_new\lib\core\l10n\tables\table_palm.dart")
t = p.read_text(encoding="utf-8")
t2 = t.replace(
"""  'palm.analyzing_hint': L10nTriple(
    'Sakin bir bakış — tıbbi tarama değil.',
    'A calm look — not a medical scan.',
    'Спокойный взгляд — не медицинское сканирование.',
  ),""",
"""  'palm.analyzing_hint': L10nTriple(
    'Gerçek el fotoğrafına bakıyorum — tıbbi tarama değil.',
    'Looking at your real hand photo — not a medical scan.',
    'Смотрю на реальное фото руки — не медицинское сканирование.',
  ),""",
)
t2 = t2.replace(
"""  'palm.source_note': L10nTriple(
    'OR görüntü yorumu — avuç fotoğrafından okunan sembolik bir bakış.',
    'OR image reading — a symbolic look from the palm photograph.',
    'OR чтение изображения — символический взгляд по фото ладони.',
  ),""",
"""  'palm.source_note': L10nTriple(
    'Avuç fotoğrafına bakıldı; yorum yansıtıcı ve semboliktir — teşhis veya kehanet değil.',
    'Your palm photo was read; the reflection is symbolic — not diagnosis or prediction.',
    'Фото ладони просмотрено; толкование символическое — не диагноз и не предсказание.',
  ),""",
)
assert t2 != t, "l10n unchanged"
p.write_text(t2, encoding="utf-8")
print("02 l10n honesty")

# 3) Prefer raw vision line text in beats when already observational
# PalmFortuneBeats.meaning may overwrite — check if we should pass vision first in sections
p = Path(r"c:\Dev\oracly_new\lib\features\palm\presentation\palm_result_sections.dart")
t = p.read_text(encoding="utf-8")
old = """  String _line(String lane, String raw, int seed) {
    final seen = PalmObservation.line(raw);
    if (seen.isEmpty) return '';
    return PalmFortuneBeats.meaning(lane, seen, seed);
  }"""
new = """  String _line(String lane, String raw, int seed) {
    final seen = PalmObservation.line(raw);
    if (seen.isEmpty) return '';
    // Keep vision prose when it already reads as observation, not a dictionary.
    if (seen.length >= 40 && !FortuneVoice.looksRobotic(seen)) {
      return seen;
    }
    return PalmFortuneBeats.meaning(lane, seen, seed);
  }"""
assert old in t, "line method missing"
p.write_text(t.replace(old, new), encoding="utf-8")
print("03 vision-first lanes")

# 4) Compact OR palm handoff
p = Path(r"c:\Dev\oracly_new\lib\features\ai\oracle_conversation\models\oracle_reading_context_sources.dart")
t = p.read_text(encoding="utf-8")
start = t.find("  static OracleReadingContext palm(PalmReading reading) {")
end = t.find("  static OracleReadingContext dailyMessage({")
assert start >= 0 and end > start
new = """  static OracleReadingContext palm(PalmReading reading) {
    final symbols = reading.symbols.take(6).toList();
    String clip(String raw, [int max = 220]) =>
        OracleReadingContextText.shortSummary(raw, maxLen: max);
    final full = [
      'El: ${reading.hand.label}',
      if (reading.overall.trim().isNotEmpty) 'Genel: ${clip(reading.overall, 280)}',
      if (reading.heartLine.trim().isNotEmpty) 'Kalp: ${clip(reading.heartLine, 120)}',
      if (reading.headLine.trim().isNotEmpty) 'Zihin: ${clip(reading.headLine, 120)}',
      if (reading.lifeLine.trim().isNotEmpty) 'Yaşam: ${clip(reading.lifeLine, 120)}',
      if (reading.fateLine.trim().isNotEmpty) 'Yön: ${clip(reading.fateLine, 120)}',
      if (symbols.isNotEmpty) 'İzler: ${symbols.join(', ')}',
    ].where((e) => e.trim().isNotEmpty).join('\\n\\n');
    return OracleReadingContext(
      sessionId: reading.id,
      kind: OracleReadingKind.palm,
      sourceLabel: 'El Falı',
      spreadLabel: reading.hand.label,
      deckId: 'palm',
      deckName: 'El Falı',
      readingTitle: 'El yorumu',
      cardsSummary:
          symbols.isEmpty ? clip(reading.overall, 120) : symbols.join(', '),
      interpretationSummary: clip(reading.overall),
      fullInterpretation: full,
      cardNames: symbols,
    );
  }

"""
p.write_text(t[:start] + new + t[end:], encoding="utf-8")
print("04 OR palm compact")