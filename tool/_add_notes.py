from pathlib import Path

entries = {
  "star.planet.moon.note.0": ("İhtiyacı söylemek, fırtınaya çevirmemek.", "Name the need without turning it into a storm.", "Назови потребность, не превращая её в бурю."),
  "star.planet.moon.note.1": ("Sakinken yazmak, geceye ertelememek.", "Write while calm; do not postpone to night.", "Пиши в спокойствии; не откладывай на ночь."),
  "star.planet.moon.note.2": ("Alan açmak; her şeyi taşımak zorunda olmamak.", "Make room; you do not have to carry everything.", "Освободи место; не обязан нести всё."),
  "star.planet.mercury.note.0": ("Açık söz, dağınık sohbetten daha güçlü.", "Clear words beat scattered talk.", "Ясные слова сильнее разрозненной речи."),
  "star.planet.mercury.note.1": ("Tek konuyu bitirmek, onunu yüzeyden geçmemek.", "Finish one topic instead of skimming ten.", "Заверши одну тему, а не скользи по десяти."),
  "star.planet.mercury.note.2": ("Dinlemek, konuşmaktan daha kazandırabilir.", "Listening can reward more than speaking.", "Слушание иногда ценнее речи."),
  "star.planet.venus.note.0": ("Küçük ve gerçek bir jest yeter.", "A small, real gesture is enough.", "Достаточно малого, настоящего жеста."),
  "star.planet.venus.note.1": ("Uymayan bağda zorlamamak.", "Do not force a bond that does not fit.", "Не форсируй связь, которая не подходит."),
  "star.planet.venus.note.2": ("Ortamı sadeleştirmek ritmi yumuşatır.", "Simplifying the space softens the rhythm.", "Упрощение пространства смягчает ритм."),
  "star.planet.mars.note.0": ("Tek net hamle, dağınık çatışmadan daha doğru.", "One clear move beats scattered conflict.", "Один ясный шаг лучше разрозненного конфликта."),
  "star.planet.mars.note.1": ("İradeyi bir hedefe kilitlemek.", "Lock will to one target.", "Зафиксируй волю на одной цели."),
  "star.planet.mars.note.2": ("Ölçülü atmak, ertelemek değil.", "Move with measure — not delay.", "Действуй с мерой — не откладывай."),
  "star.planet.jupiter.note.0": ("Her kapıya aynı anda girme; birini seç.", "Do not enter every door at once; choose one.", "Не входи во все двери сразу; выбери одну."),
  "star.planet.jupiter.note.1": ("Bir fikri uygulamak, yalnızca büyütmekten iyi.", "Apply one idea instead of only enlarging it.", "Примени одну идею, а не только раздувай её."),
  "star.planet.jupiter.note.2": ("İç büyüme dış gösterişten daha değerli.", "Inner growth matters more than outer display.", "Внутренний рост важнее внешнего показа."),
  "star.planet.saturn.note.0": ("Sorumluluğu paylaş; hepsini tek başına taşıma.", "Share responsibility; do not carry it all alone.", "Дели ответственность; не неси всё в одиночку."),
  "star.planet.saturn.note.1": ("Bir görevi kapat, listeyi uzatma.", "Close one task; do not lengthen the list.", "Закрой одну задачу; не удлиняй список."),
  "star.planet.saturn.note.2": ("Yapı korur; sertleşme değil, ritim tut.", "Structure protects; keep rhythm, not hardness.", "Структура защищает; держи ритм, не жёсткость."),
}

lines = []
for key, (tr, en, ru) in entries.items():
    lines.append(f"  '{key}': L10nTriple(")
    lines.append(f"    '{tr}',")
    lines.append(f"    '{en}',")
    lines.append(f"    '{ru}',")
    lines.append("  ),")

block = "\n".join(lines) + "\n"
p = Path('lib/core/l10n/tables/table_star_voice.dart')
t = p.read_text(encoding='utf-8')
t = t.replace('\n};\n', '\n' + block + '};\n', 1)
p.write_text(t, encoding='utf-8')
print('added', len(entries), 'notes')
