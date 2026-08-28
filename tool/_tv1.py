from pathlib import Path

def w(path, body):
    Path(path).write_text(body, encoding="utf-8", newline="\n")
    print(path, len(body.splitlines()))

# Update key l10n strings in table_tarot.dart
p = Path("lib/core/l10n/tables/table_tarot.dart")
t = p.read_text(encoding="utf-8")
repls = [
(
'''  'tarot.start': L10nTriple(
    'Bir soru tut.\\nKartların hikâyeyi açsın.',
    'Hold a question.\\nLet the cards open the story.',
    'Держи вопрос.\\nКарты откроют историю.',
  ),''',
'''  'tarot.start': L10nTriple(
    'Bugün evren sana ne fısıldıyor?',
    'What is the universe whispering to you today?',
    'Что вселенная шепчет тебе сегодня?',
  ),'''
),
(
'''  'tarot.entry.cta': L10nTriple(
    'AÇILIMI BAŞLAT',
    'BEGIN THE SPREAD',
    'НАЧАТЬ РАСКЛАД',
  ),''',
'''  'tarot.entry.cta': L10nTriple(
    'RİTÜELE GİR',
    'ENTER THE RITUAL',
    'ВОЙТИ В РИТУАЛ',
  ),'''
),
(
'''  'tarot.spread.single.blurb': L10nTriple(
    'Bugünün ana işareti',
    'Today\\'s main sign',
    'Главный знак сегодня',
  ),''',
'''  'tarot.spread.single.blurb': L10nTriple(
    'Bugün bilmem gereken ne?',
    'What do I need to know today?',
    'Что мне нужно знать сегодня?',
  ),'''
),
(
'''  'tarot.spread.five.blurb': L10nTriple(
    'Durumu derinlemesine aç',
    'Open the situation in depth',
    'Раскрыть ситуацию глубже',
  ),''',
'''  'tarot.spread.five.blurb': L10nTriple(
    'Durum · Zorluk · Güç · Yön',
    'Situation · Challenge · Strength · Direction',
    'Ситуация · Трудность · Сила · Путь',
  ),'''
),
(
'''  'tarot.draw.manual': L10nTriple(
    'KENDİM SEÇECEĞİM',
    'I WILL CHOOSE',
    'Я ВЫБЕРУ',
  ),''',
'''  'tarot.draw.manual': L10nTriple(
    'KARTI BEN ÇEKEYİM',
    'I WILL DRAW',
    'Я ВЫТЯНУ',
  ),'''
),
(
'''  'tarot.draw.manual_blurb': L10nTriple(
    'Kartın yerini sen seç.',
    'Choose a place in the fan.',
    'Выбери место в веере.',
  ),''',
'''  'tarot.draw.manual_blurb': L10nTriple(
    'Desteden bir kart çek.',
    'Draw a card from the deck.',
    'Вытяни карту из колоды.',
  ),'''
),
(
'''  'tarot.step.selection': L10nTriple(
    'Kart Seçimi',
    'Card selection',
    'Выбор карт',
  ),''',
'''  'tarot.step.selection': L10nTriple(
    'Kart Çekimi',
    'Card draw',
    'Вытягивание карт',
  ),'''
),
]
for a,b in repls:
    if a not in t:
        print("MISS:", a[:60].replace("\\n"," "))
    else:
        t = t.replace(a,b)
        print("OK", a.split("'")[1])

# Add completion whisper if missing
if "tarot.reveal.complete" not in t:
    t = t.replace(
        "'tarot.continue': L10nTriple('Devam Et', 'Continue', 'Продолжить'),",
        """'tarot.continue': L10nTriple('Devam Et', 'Continue', 'Продолжить'),
  'tarot.reveal.complete': L10nTriple(
    'Açılım tamamlandı.',
    'The spread is complete.',
    'Расклад завершён.',
  ),""",
    )
    print("added reveal.complete")

p.write_text(t, encoding="utf-8", newline="\n")
print("l10n updated")
