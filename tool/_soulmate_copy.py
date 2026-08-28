# -*- coding: utf-8 -*-
from pathlib import Path
p = Path(r"c:/Dev/oracly_new/lib/core/l10n/tables/table_soulmate.dart")
t = p.read_text(encoding="utf-8")
reps = [
(
"""  'soulmate.screen_lead': L10nTriple(
    'İsim, doğum ve isteğe bağlı bir tercih yeter. Portre bunlardan oluşur.',
    'A name, a birth date, and one optional preference are enough. The portrait is made from these.',
    'Имени, даты рождения и одного необязательного предпочтения достаточно. Портрет складывается из этого.',
  ),""",
"""  'soulmate.screen_lead': L10nTriple(
    'Birkaç sakin bilgi yeter. Portre, senin paylaştıklarından doğan sembolik bir hayal.',
    'A few calm details are enough. The portrait is a symbolic imagining born from what you share.',
    'Достаточно нескольких спокойных деталей. Портрет — символический образ из того, чем ты делишься.',
  ),""",
),
(
"""  'soulmate.honesty': L10nTriple(
    'Bu portre ve yorum, verdiğin bilgilere dayalı sembolik ve yaratıcı bir deneyimdir.',
    'This portrait and reading are a symbolic, creative experience based on what you share.',
    'Этот портрет и текст — символический творческий опыт на основе твоих данных.',
  ),""",
"""  'soulmate.honesty': L10nTriple(
    'Bu sembolik bir portre — gerçek bir kişi, kesin ruh eşi veya gelecek buluşma iddiası değil.',
    'This is a symbolic portrait — not a real person, a guaranteed soulmate, or a future meeting.',
    'Это символический портрет — не реальный человек, не гарантированная родственная душа и не встреча в будущем.',
  ),""",
),
(
"""  'soulmate.dynamics': L10nTriple('İLİŞKİ DİNAMİĞİ', 'RELATIONSHIP DYNAMIC', 'ДИНАМИКА ОТНОШЕНИЙ'),""",
"""  'soulmate.dynamics': L10nTriple('YANINDA NASIL DURABİLİR', 'HOW IT MIGHT SIT BESIDE YOU', 'КАК ЭТО МОЖЕТ БЫТЬ РЯДОМ'),""",
),
]
for old, new in reps:
    if old not in t:
        raise SystemExit("missing: " + old[:60])
    t = t.replace(old, new, 1)

# Add a third atmospheric phase if only two exist
old_draw2 = """  'soulmate.drawing_2': L10nTriple(
"""
# find drawing_2 block end - insert drawing_3 after drawing_2 block
marker = "  'soulmate.unavailable':"
if "'soulmate.drawing_3'" not in t and marker in t:
    # Find drawing_2 full triple - read around it
    i = t.find("'soulmate.drawing_2'")
    j = t.find("  'soulmate.unavailable'")
    draw2 = t[i:j]
    # append drawing_3 before unavailable
    insert = """  'soulmate.drawing_3': L10nTriple(
    'Işık yavaşça yerleşiyor…',
    'Light is settling gently…',
    'Свет мягко укладывается…',
  ),
"""
    t = t[:j] + insert + t[j:]

p.write_bytes(t.encode("utf-8"))
print("ok")
