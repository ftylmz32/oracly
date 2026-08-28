# -*- coding: utf-8 -*-
from pathlib import Path

root = Path(r"c:/Dev/oracly_new")

# table_astrology star.lead + birth_chart_hint
p = root / "lib/core/l10n/tables/table_astrology.dart"
t = p.read_text(encoding="utf-8")
reps = [
("""  'star.lead': L10nTriple(
    'Bu sembolik gök yolu\\nsenin hakkında hangi hikâyeyi öneriyor?',
    'What story does this symbolic\\ncelestial path suggest about you?',
    'Какую историю предлагает тебе\\nэтот символический небесный путь?',
  ),""",
"""  'star.lead': L10nTriple(
    'Arşivindeki yaprak\\nsenin hakkında hangi hikâyeyi tutuyor?',
    'What story does this archive leaf\\nhold about you?',
    'Какую историю хранит о тебе\\nэтот лист архива?',
  ),"""),
("""  'star.birth_chart_hint': L10nTriple(
    'Sembolik gök yolunun senin hakkında önerdiği hikâye. Hüküm değil.',
    'The story this symbolic celestial path suggests about you. Not a verdict.',
    'История, которую предлагает тебе этот символический путь. Не приговор.',
  ),""",
"""  'star.birth_chart_hint': L10nTriple(
    'Kişisel yıldızname arşivinin senin hakkında tuttuğu fasıl. Hüküm değil.',
    'The chapter your personal star-archive holds about you. Not a verdict.',
    'Глава, которую хранит о тебе личный звёздный архив. Не приговор.',
  ),"""),
("""  'star.capability': L10nTriple(
    'Güneş burcuna göre sembolik bir yıldızname yolu — hüküm değil, kişisel bir fasıl.',
    'A symbolic star-archive path from the sun sign — a personal chapter, not a verdict.',
    'Символический путь звёздной книги по Солнцу — личная глава, не приговор.',
  ),""",
"""  'star.capability': L10nTriple(
    'Güneş burcuna göre kişisel bir yıldızname arşivi — hüküm değil, kendi hikâyenin faslı.',
    'A personal star-archive from the sun sign — a chapter of your story, not a verdict.',
    'Личный звёздный архив по Солнцу — глава твоей истории, не приговор.',
  ),"""),
]
for old, new in reps:
    if old not in t:
        raise SystemExit("missing: " + old[:50])
    t = t.replace(old, new, 1)
p.write_bytes(t.encode("utf-8"))
print("astrology table ok")

# home caption
h = root / "lib/core/l10n/tables/table_home.dart"
th = h.read_text(encoding="utf-8")
oldh = """  'home.discovery.star_map.caption': L10nTriple(
    'Yıldız arşivi',
    'Star archive',
    'Звёздный архив',
  ),"""
newh = """  'home.discovery.star_map.caption': L10nTriple(
    'Kişisel hikâye arşivi',
    'Personal story archive',
    'Архив личной истории',
  ),"""
if oldh not in th:
    raise SystemExit("home caption missing")
h.write_bytes(th.replace(oldh, newh, 1).encode("utf-8"))
print("home ok")

# nav hint if sky-like
v = root / "lib/core/l10n/tables/table_voice.dart"
tv = v.read_text(encoding="utf-8")
# print nearby
idx = tv.find("nav.hint.star")
print(tv[idx:idx+250])
