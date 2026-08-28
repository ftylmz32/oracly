from pathlib import Path
p = Path(r"c:\Dev\oracly_new\lib\features\ai\oracle_conversation\models\oracle_reading_context_sources.dart")
t = p.read_text(encoding="utf-8")
start = t.find("  static OracleReadingContext coffee(CoffeeReading reading) {")
end = t.find("  static OracleReadingContext palm(PalmReading reading) {")
print("bounds", start, end)
assert start >= 0 and end > start
new = (
"  static OracleReadingContext coffee(CoffeeReading reading) {\n"
"    final symbols = reading.symbols.map((s) => s.name).take(6).toList();\n"
"    String clip(String raw, [int max = 220]) =>\n"
"        OracleReadingContextText.shortSummary(raw, maxLen: max);\n"
"    final full = [\n"
"      if (reading.visualObservation.trim().isNotEmpty)\n"
"        'Gorulen: ${clip(reading.visualObservation, 160)}',\n"
"      if (reading.overall.trim().isNotEmpty) 'Genel: ${clip(reading.overall, 280)}',\n"
"      if (symbols.isNotEmpty) 'Izler: ${symbols.join(', ')}',\n"
"      if (reading.takeaway.trim().isNotEmpty) 'Dikkat: ${clip(reading.takeaway, 160)}',\n"
"    ].where((e) => e.trim().isNotEmpty).join('\\n\\n');\n"
"    return OracleReadingContext(\n"
"      sessionId: reading.id,\n"
"      kind: OracleReadingKind.coffee,\n"
"      sourceLabel: 'Kahve Fali',\n"
"      spreadLabel: 'Fincan',\n"
"      deckId: 'coffee',\n"
"      deckName: 'Kahve Fali',\n"
"      readingTitle: 'Fincan yorumu',\n"
"      cardsSummary:\n"
"          symbols.isEmpty ? clip(reading.overall, 120) : symbols.join(', '),\n"
"      interpretationSummary: clip(reading.overall),\n"
"      fullInterpretation: full,\n"
"      cardNames: symbols,\n"
"    );\n"
"  }\n"
"\n"
)
# Fix Turkish labels properly
new = new.replace("Gorulen:", "Görülen:").replace("Izler:", "İzler:").replace("Kahve Fali", "Kahve Falı")
p.write_text(t[:start] + new + t[end:], encoding="utf-8")
print("ok", "take(6)" in p.read_text(encoding="utf-8"))