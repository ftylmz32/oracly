# -*- coding: utf-8 -*-
from pathlib import Path

root = Path(r"c:/Dev/oracly_new")
astro = root / "lib/core/l10n/tables/table_astrology.dart"
t = astro.read_text(encoding="utf-8")

def rep(old, new, label):
    global t
    if old not in t:
        raise SystemExit("missing: " + label)
    t = t.replace(old, new, 1)
    print("ok", label)

rep(
"""  'astro.today_title': L10nTriple(
    'Gökyüzünün bugünkü önerisi',
    'What the sky suggests today',
    'Что предлагает небо сегодня',
  ),""",
"""  'astro.today_title': L10nTriple(
    'Güneş burcunun bugünkü ritmi',
    "Today's sun-sign rhythm",
    'Сегодняшний ритм солнечного знака',
  ),""",
"today_title")

rep(
"""  'astro.lead': L10nTriple(
    'Bugün gökyüzü\\nsana ne öneriyor?',
    'What does the sky\\nsuggest today?',
    'Что небо предлагает\\nтебе сегодня?',
  ),""",
"""  'astro.lead': L10nTriple(
    'Bu Güneş burcu\\nbugün nasıl duruyor?',
    'How does this sun sign\\nsit with you today?',
    'Как этот солнечный знак\\nстоит сегодня?',
  ),""",
"lead")

rep(
"""  'astro.loading_today_sky': L10nTriple(
    'Bugünkü gökyüzünü dikkatle okuyorum...',
    \"Reading today's sky with care...\",
    'Внимательно читаю сегодняшнее небо...',
  ),""",
"""  'astro.loading_today_sky': L10nTriple(
    'Güneş burcu ritmini dikkatle okuyorum...',
    'Reading the sun-sign rhythm with care...',
    'Внимательно читаю ритм солнечного знака...',
  ),""",
"loading")

rep(
"""  'astro.your_sky_title': L10nTriple(
    'BUGÜNKÜ GÖKYÜZÜ',
    \"TODAY'S SKY\",
    'СЕГОДНЯШНЕЕ НЕБО',
  ),""",
"""  'astro.your_sky_title': L10nTriple(
    'GÜNEŞ BURCUN',
    'YOUR SUN SIGN',
    'ТВОЙ СОЛНЕЧНЫЙ ЗНАК',
  ),""",
"your_sky")

rep(
"""  'astro.lane_love': L10nTriple('AŞK', 'LOVE', 'ЛЮБОВЬ'),
  'astro.lane_work': L10nTriple('İŞ & YÖN', 'WORK & PATH', 'ДЕЛО И ПУТЬ'),
  'astro.lane_inner': L10nTriple('NETLİK', 'CLARITY', 'ЯСНОСТЬ'),
  'astro.report_theme': L10nTriple(
    'GÜNÜN TEMASI',
    \"TODAY'S THEME\",
    'ТЕМА ДНЯ',
  ),
  'astro.report_message': L10nTriple(
    'SANA ÖZEL',
    'FOR YOU',
    'ДЛЯ ТЕБЯ',
  ),
  'astro.report_attention': L10nTriple(
    'DİKKAT NOKTASI',
    'WORTH NOTICING',
    'НА ЧТО ОБРАТИТЬ ВНИМАНИЕ',
  ),
  'astro.report_next': L10nTriple(
    'BUGÜNKÜ ADIM',
    \"TODAY'S STEP\",
    'ШАГ НА СЕГОДНЯ',
  ),
  'astro.report_depths': L10nTriple(
    'BUGÜNÜN KATMANLARI',
    \"TODAY'S LAYERS\",
    'СЛОИ ДНЯ',
  ),""",
"""  'astro.lane_love': L10nTriple('YAKINLIK', 'CLOSENESS', 'БЛИЗОСТЬ'),
  'astro.lane_work': L10nTriple('YÖN', 'DIRECTION', 'НАПРАВЛЕНИЕ'),
  'astro.lane_inner': L10nTriple('İÇERİDE', 'WITHIN', 'ВНУТРИ'),
  'astro.report_theme': L10nTriple(
    'GÖZLEM',
    'OBSERVATION',
    'НАБЛЮДЕНИЕ',
  ),
  'astro.report_message': L10nTriple(
    'NE ANLAMA GELİYOR',
    'WHAT IT MEANS',
    'ЧТО ЭТО ЗНАЧИТ',
  ),
  'astro.report_attention': L10nTriple(
    'NÜANS',
    'NUANCE',
    'НЮАНС',
  ),
  'astro.report_next': L10nTriple(
    'YANSIMA',
    'REFLECTION',
    'ОТРАЖЕНИЕ',
  ),
  'astro.report_depths': L10nTriple(
    'DERİNLİKLER',
    'DEPTHS',
    'ГЛУБИНЫ',
  ),""",
"lanes_report")

astro.write_bytes(t.encode("utf-8"))
print("wrote astrology")

birth = root / "lib/core/l10n/tables/table_birth_more.dart"
t2 = birth.read_text(encoding="utf-8")
old2 = """  'preview.astro_detail': L10nTriple(
    'Bu bir yansıma, hüküm değil. Güneş burcunun bugünkü ritminden okunuyor.',
    'This is a reflection, not a verdict. It is read from today’s sun-sign rhythm.',
    'Это отражение, не приговор. Читается из сегодняшнего ритма солнечного знака.',
  ),"""
new2 = """  'preview.astro_detail': L10nTriple(
    'Bu bir yansıma, hüküm değil. Yerel Güneş burcu kataloğundan okunuyor — canlı ephemeris değil.',
    'This is a reflection, not a verdict. It is read from a local sun-sign catalogue — not a live ephemeris.',
    'Это отражение, не приговор. Читается из локального каталога солнечного знака — не живой эфемериды.',
  ),"""
if old2 not in t2:
    raise SystemExit("preview missing")
birth.write_bytes(t2.replace(old2, new2, 1).encode("utf-8"))
print("wrote birth_more")
