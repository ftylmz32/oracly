# -*- coding: utf-8 -*-
from pathlib import Path
ROOT = Path(r"C:\Dev\oracly_new")

def W(rel, text):
    (ROOT/rel).write_text(text, encoding="utf-8", newline="\n")
    print("wrote", rel, len(text))

def P(rel, old, new):
    p = ROOT/rel
    t = p.read_text(encoding="utf-8")
    if old not in t:
        raise SystemExit("MISSING "+rel)
    p.write_text(t.replace(old, new, 1), encoding="utf-8", newline="\n")
    print("patched", rel)

# Build insight table with unicode escapes for safety in this source file
T = lambda tr, en, ru: f"L10nTriple('{tr}', '{en}', '{ru}')"

rows = []
def add(key, tr, en, ru):
    rows.append(f"  '{key}': {T(tr, en, ru)},")

add("birth.conj_and", "ve", "and", "\u0438")
add("birth.element.fire", "Ate\u015f", "Fire", "\u041e\u0433\u043e\u043d\u044c")
add("birth.element.earth", "Toprak", "Earth", "\u0417\u0435\u043c\u043b\u044f")
add("birth.element.air", "Hava", "Air", "\u0412\u043e\u0437\u0434\u0443\u0445")
add("birth.element.water", "Su", "Water", "\u0412\u043e\u0434\u0430")
add("birth.energy.label", "{element} G\u00fcne\u015f", "{element} Sun", "\u0421\u043e\u043b\u043d\u0446\u0435 {element}")
add(
    "birth.energy.summary",
    "{sign} G\u00fcne\u015fi, {element} elementinin tonunu ta\u015f\u0131r. Ay, Y\u00fckselen ve evler ger\u00e7ek bir hesap kayna\u011f\u0131 ba\u011flan\u0131nca eklenecek.",
    "The {sign} Sun carries the tone of the {element} element. Moon, Rising, and houses will be added when a real calculation source is connected.",
    "\u0421\u043e\u043b\u043d\u0446\u0435 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign} \u043d\u0435\u0441\u0451\u0442 \u0442\u043e\u043d \u0441\u0442\u0438\u0445\u0438\u0438 {element}. \u041b\u0443\u043d\u0430, \u0410\u0441\u0446\u0435\u043d\u0434\u0435\u043d\u0442 \u0438 \u0434\u043e\u043c\u0430 \u043f\u043e\u044f\u0432\u044f\u0442\u0441\u044f \u043f\u0440\u0438 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u0438 \u0440\u0435\u0430\u043b\u044c\u043d\u043e\u0433\u043e \u0440\u0430\u0441\u0447\u0451\u0442\u0430.",
)
add(
    "birth.result.summary",
    "{sign} G\u00fcne\u015fi, {energy} tonunu ta\u015f\u0131r. {ephemeris}",
    "The {sign} Sun carries a {energy} tone. {ephemeris}",
    "\u0421\u043e\u043b\u043d\u0446\u0435 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign} \u043d\u0435\u0441\u0451\u0442 \u0442\u043e\u043d: {energy}. {ephemeris}",
)
add(
    "birth.result.strong_fallback",
    "{sign} G\u00fcne\u015finin bilinen g\u00fc\u00e7l\u00fc yan\u0131, g\u00f6r\u00fcn\u00fcr kimli\u011fini sakin tutmakt\u0131r.",
    "A known strength of the {sign} Sun is keeping visible identity calm.",
    "\u0418\u0437\u0432\u0435\u0441\u0442\u043d\u0430\u044f \u0441\u0438\u043b\u0430 \u0421\u043e\u043b\u043d\u0446\u0430 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign} \u2014 \u0441\u043f\u043e\u043a\u043e\u0439\u043d\u043e \u0434\u0435\u0440\u0436\u0430\u0442\u044c \u0432\u0438\u0434\u0438\u043c\u0443\u044e \u0438\u0434\u0435\u043d\u0442\u0438\u0447\u043d\u043e\u0441\u0442\u044c.",
)
add("birth.house_of", "{n}. ev", "{n}. house", "{n}. \u0434\u043e\u043c")
add("birth.placement.moon", "Ay {sign}", "Moon in {sign}", "\u041b\u0443\u043d\u0430 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign}")
add("birth.placement.rising", "Y\u00fckselen {sign}", "Rising {sign}", "\u0410\u0441\u0446\u0435\u043d\u0434\u0435\u043d\u0442 {sign}")
add("birth.placement.planet", "{planet} {sign}", "{planet} in {sign}", "{planet} \u0432 \u0437\u043d\u0430\u043a\u0435 {sign}")
add("birth.theme.identity", "Kimlik", "Identity", "\u0418\u0434\u0435\u043d\u0442\u0438\u0447\u043d\u043e\u0441\u0442\u044c")
add(
    "birth.theme.identity_body",
    "{sign} G\u00fcne\u015fi, {traits} yanlar\u0131n\u0131 \u00f6ne \u00e7\u0131karmay\u0131 sevebilir.",
    "The {sign} Sun may enjoy bringing out {traits} sides.",
    "\u0421\u043e\u043b\u043d\u0446\u0435 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign} \u043c\u043e\u0436\u0435\u0442 \u043b\u044e\u0431\u0438\u0442\u044c \u043f\u0440\u043e\u044f\u0432\u043b\u044f\u0442\u044c \u0441\u0442\u043e\u0440\u043e\u043d\u044b: {traits}.",
)
add(
    "birth.insight.sun_body",
    "{sign} G\u00fcne\u015fi, kimli\u011fini {traits} bir t\u0131n\u0131yla ta\u015f\u0131r. {glossary}",
    "The {sign} Sun carries identity with a {traits} tone. {glossary}",
    "\u0421\u043e\u043b\u043d\u0446\u0435 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign} \u043d\u0435\u0441\u0451\u0442 \u0438\u0434\u0435\u043d\u0442\u0438\u0447\u043d\u043e\u0441\u0442\u044c \u0441 \u0442\u043e\u043d\u043e\u043c: {traits}. {glossary}",
)
add(
    "birth.insight.moon_body",
    "Ay {sign}, duygusal d\u00fcnyanda {trait} bir ton b\u0131rak\u0131r. {glossary}",
    "Moon in {sign} leaves a {trait} tone in the emotional world. {glossary}",
    "\u041b\u0443\u043d\u0430 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign} \u043e\u0441\u0442\u0430\u0432\u043b\u044f\u0435\u0442 {trait} \u0442\u043e\u043d \u0432\u043e \u0432\u043d\u0443\u0442\u0440\u0435\u043d\u043d\u0435\u043c \u043c\u0438\u0440\u0435. {glossary}",
)
add(
    "birth.insight.rising_body",
    "Y\u00fckselen {sign}, ilk izlenimde {trait} bir kap\u0131 a\u00e7ar. {glossary}",
    "Rising {sign} opens a {trait} door at first impression. {glossary}",
    "\u0410\u0441\u0446\u0435\u043d\u0434\u0435\u043d\u0442 {sign} \u043e\u0442\u043a\u0440\u044b\u0432\u0430\u0435\u0442 {trait} \u0434\u0432\u0435\u0440\u044c \u043f\u0440\u0438 \u043f\u0435\u0440\u0432\u043e\u043c \u0432\u043f\u0435\u0447\u0430\u0442\u043b\u0435\u043d\u0438\u0438. {glossary}",
)
add(
    "birth.insight.core_sun",
    "\u00d6z\u00fcn {sign} enerjisiyle {traits} bir t\u0131n\u0131 ta\u015f\u0131yor olabilir.",
    "Your core may carry a {traits} tone with {sign} energy.",
    "\u0421\u0443\u0442\u044c \u043c\u043e\u0436\u0435\u0442 \u043d\u0435\u0441\u0442\u0438 {traits} \u0442\u043e\u043d \u0441 \u044d\u043d\u0435\u0440\u0433\u0438\u0435\u0439 \u0437\u043d\u0430\u043a\u0430 {sign}.",
)
add(
    "birth.insight.core_moon",
    "Ay {sign}, dinlenmeye ihtiya\u00e7 duydu\u011funda {trait} bir ton arayabilece\u011fini d\u00fc\u015f\u00fcnd\u00fcr\u00fcr.",
    "Moon in {sign} suggests you may seek a {trait} tone when you need rest.",
    "\u041b\u0443\u043d\u0430 \u0432 \u0437\u043d\u0430\u043a\u0435 {sign} \u043d\u0430\u043c\u0435\u043a\u0430\u0435\u0442, \u0447\u0442\u043e \u0432 \u043e\u0442\u0434\u044b\u0445\u0435 \u0442\u044b \u043c\u043e\u0436\u0435\u0448\u044c \u0438\u0441\u043a\u0430\u0442\u044c {trait} \u0442\u043e\u043d.",
)
add(
    "birth.insight.core_rising",
    "Y\u00fckselen {sign}, tan\u0131\u015f\u0131ld\u0131\u011f\u0131nda {trait} bir izlenim b\u0131rakman m\u00fcmk\u00fcn.",
    "Rising {sign} may leave a {trait} impression when you are met.",
    "\u0410\u0441\u0446\u0435\u043d\u0434\u0435\u043d\u0442 {sign} \u043c\u043e\u0436\u0435\u0442 \u043e\u0441\u0442\u0430\u0432\u043b\u044f\u0442\u044c {trait} \u0432\u043f\u0435\u0447\u0430\u0442\u043b\u0435\u043d\u0438\u0435 \u043f\u0440\u0438 \u0437\u043d\u0430\u043a\u043e\u043c\u0441\u0442\u0432\u0435.",
)

planets = [
    ("sun", "G\u00fcne\u015f", "Sun", "\u0421\u043e\u043b\u043d\u0446\u0435"),
    ("moon", "Ay", "Moon", "\u041b\u0443\u043d\u0430"),
    ("ascendant", "Y\u00fckselen", "Rising", "\u0410\u0441\u0446\u0435\u043d\u0434\u0435\u043d\u0442"),
    ("mercury", "Merk\u00fcr", "Mercury", "\u041c\u0435\u0440\u043a\u0443\u0440\u0438\u0439"),
    ("venus", "Ven\u00fcs", "Venus", "\u0412\u0435\u043d\u0435\u0440\u0430"),
    ("mars", "Mars", "Mars", "\u041c\u0430\u0440\u0441"),
    ("jupiter", "J\u00fcpiter", "Jupiter", "\u042e\u043f\u0438\u0442\u0435\u0440"),
    ("saturn", "Sat\u00fcrn", "Saturn", "\u0421\u0430\u0442\u0443\u0440\u043d"),
    ("uranus", "Uran\u00fcs", "Uranus", "\u0423\u0440\u0430\u043d"),
    ("neptune", "Nept\u00fcn", "Neptune", "\u041d\u0435\u043f\u0442\u0443\u043d"),
    ("pluto", "Pl\u00fcton", "Pluto", "\u041f\u043b\u0443\u0442\u043e\u043d"),
]
for pid, tr, en, ru in planets:
    add(f"planet.{pid}", tr, en, ru)

aspects = [
    ("conjunction", "Kavu\u015fum", "Conjunction", "\u0421\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435"),
    ("sextile", "Sekstil", "Sextile", "\u0421\u0435\u043a\u0441\u0442\u0438\u043b\u044c"),
    ("square", "Kare", "Square", "\u041a\u0432\u0430\u0434\u0440\u0430\u0442"),
    ("trine", "\u00dc\u00e7gen", "Trine", "\u0422\u0440\u0438\u043d"),
    ("opposition", "Kar\u015f\u0131t", "Opposition", "\u041e\u043f\u043f\u043e\u0437\u0438\u0446\u0438\u044f"),
]
for aid, tr, en, ru in aspects:
    add(f"aspect.{aid}", tr, en, ru)

traits = {
    "aries": (("Cesur", "Brave", "\u0421\u043c\u0435\u043b\u044b\u0439"), ("Giri\u015fken", "Assertive", "\u0418\u043d\u0438\u0446\u0438\u0430\u0442\u0438\u0432\u043d\u044b\u0439")),
    "taurus": (("Kararl\u0131", "Steady", "\u0421\u0442\u043e\u0439\u043a\u0438\u0439"), ("G\u00fcvenilir", "Reliable", "\u041d\u0430\u0434\u0451\u0436\u043d\u044b\u0439")),
    "gemini": (("Merakl\u0131", "Curious", "\u041b\u044e\u0431\u043e\u043f\u044b\u0442\u043d\u044b\u0439"), ("\u0130leti\u015fimci", "Communicative", "\u041e\u0431\u0449\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439")),
    "cancer": (("Koruyucu", "Protective", "\u0417\u0430\u0431\u043e\u0442\u043b\u0438\u0432\u044b\u0439"), ("Sezgisel", "Intuitive", "\u0418\u043d\u0442\u0443\u0438\u0442\u0438\u0432\u043d\u044b\u0439")),
    "leo": (("C\u00f6mert", "Generous", "\u0429\u0435\u0434\u0440\u044b\u0439"), ("Yarat\u0131c\u0131", "Creative", "\u0422\u0432\u043e\u0440\u0447\u0435\u0441\u043a\u0438\u0439")),
    "virgo": (("Analitik", "Analytical", "\u0410\u043d\u0430\u043b\u0438\u0442\u0438\u0447\u043d\u044b\u0439"), ("D\u00fczenli", "Orderly", "\u041e\u0440\u0433\u0430\u043d\u0438\u0437\u043e\u0432\u0430\u043d\u043d\u044b\u0439")),
    "libra": (("Diplomatik", "Diplomatic", "\u0414\u0438\u043f\u043b\u043e\u043c\u0430\u0442\u0438\u0447\u043d\u044b\u0439"), ("Adil", "Fair", "\u0421\u043f\u0440\u0430\u0432\u0435\u0434\u043b\u0438\u0432\u044b\u0439")),
    "scorpio": (("Derin", "Deep", "\u0413\u043b\u0443\u0431\u043e\u043a\u0438\u0439"), ("Kararl\u0131", "Determined", "\u0420\u0435\u0448\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439")),
    "sagittarius": (("\u00d6zg\u00fcr", "Free", "\u0421\u0432\u043e\u0431\u043e\u0434\u043d\u044b\u0439"), ("\u0130yimser", "Optimistic", "\u041e\u043f\u0442\u0438\u043c\u0438\u0441\u0442\u0438\u0447\u043d\u044b\u0439")),
    "capricorn": (("Disiplinli", "Disciplined", "\u0414\u0438\u0441\u0446\u0438\u043f\u043b\u0438\u043d\u0438\u0440\u043e\u0432\u0430\u043d\u043d\u044b\u0439"), ("Sorumlu", "Responsible", "\u041e\u0442\u0432\u0435\u0442\u0441\u0442\u0432\u0435\u043d\u043d\u044b\u0439")),
    "aquarius": (("\u00d6zg\u00fcn", "Original", "\u0421\u0430\u043c\u043e\u0431\u044b\u0442\u043d\u044b\u0439"), ("\u0130nsanc\u0131l", "Humane", "\u0413\u0443\u043c\u0430\u043d\u0438\u0447\u043d\u044b\u0439")),
    "pisces": (("Empatik", "Empathic", "\u042d\u043c\u043f\u0430\u0442\u0438\u0447\u043d\u044b\u0439"), ("Hayalperest", "Imaginative", "\u041c\u0435\u0447\u0442\u0430\u0442\u0435\u043b\u044c\u043d\u044b\u0439")),
}
for sid, (t0, t1) in traits.items():
    add(f"birth.trait.{sid}.0", *t0)
    add(f"birth.trait.{sid}.1", *t1)

careers = {
    "aries": ("Giri\u015fimci ve rekabet\u00e7i.", "Entrepreneurial and competitive.", "\u041f\u0440\u0435\u0434\u043f\u0440\u0438\u0438\u043c\u0447\u0438\u0432\u044b\u0439 \u0438 \u0441\u043e\u0440\u0435\u0432\u043d\u043e\u0432\u0430\u0442\u0435\u043b\u044c\u043d\u044b\u0439."),
    "taurus": ("\u0130stikrarl\u0131 ve kalite odakl\u0131.", "Steady and quality-focused.", "\u0421\u0442\u0430\u0431\u0438\u043b\u044c\u043d\u044b\u0439 \u0438 \u043e\u0440\u0438\u0435\u043d\u0442\u0438\u0440\u043e\u0432\u0430\u043d\u043d\u044b\u0439 \u043d\u0430 \u043a\u0430\u0447\u0435\u0441\u0442\u0432\u043e."),
    "gemini": ("\u00c7ok y\u00f6nl\u00fc ve h\u0131zl\u0131 \u00f6\u011frenen.", "Versatile and a quick learner.", "\u041c\u043d\u043e\u0433\u043e\u0433\u0440\u0430\u043d\u043d\u044b\u0439 \u0438 \u0431\u044b\u0441\u0442\u0440\u043e \u043e\u0431\u0443\u0447\u0430\u044e\u0449\u0438\u0439\u0441\u044f."),
    "cancer": ("Besleyici ve destekleyici roller.", "Nurturing and supportive roles.", "\u0417\u0430\u0431\u043e\u0442\u043b\u0438\u0432\u044b\u0435 \u0438 \u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u044e\u0449\u0438\u0435 \u0440\u043e\u043b\u0438."),
    "leo": ("Sahne ve yarat\u0131c\u0131 alanlar.", "Stage and creative fields.", "\u0421\u0446\u0435\u043d\u0430 \u0438 \u0442\u0432\u043e\u0440\u0447\u0435\u0441\u043a\u0438\u0435 \u0441\u0444\u0435\u0440\u044b."),
    "virgo": ("Organizasyon ve uzmanl\u0131k.", "Organization and craft.", "\u041e\u0440\u0433\u0430\u043d\u0438\u0437\u0430\u0446\u0438\u044f \u0438 \u043c\u0430\u0441\u0442\u0435\u0440\u0441\u0442\u0432\u043e."),
    "libra": ("Arabuluculuk ve tasar\u0131m.", "Mediation and design.", "\u041f\u043e\u0441\u0440\u0435\u0434\u043d\u0438\u0447\u0435\u0441\u0442\u0432\u043e \u0438 \u0434\u0438\u0437\u0430\u0439\u043d."),
    "scorpio": ("Ara\u015ft\u0131rma ve strateji.", "Research and strategy.", "\u0418\u0441\u0441\u043b\u0435\u0434\u043e\u0432\u0430\u043d\u0438\u0435 \u0438 \u0441\u0442\u0440\u0430\u0442\u0435\u0433\u0438\u044f."),
    "sagittarius": ("E\u011fitim ve ke\u015fif.", "Learning and exploration.", "\u041e\u0431\u0443\u0447\u0435\u043d\u0438\u0435 \u0438 \u0438\u0441\u0441\u043b\u0435\u0434\u043e\u0432\u0430\u043d\u0438\u0435."),
    "capricorn": ("Y\u00f6netim ve yap\u0131.", "Leadership and structure.", "\u0423\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u0438\u0435 \u0438 \u0441\u0442\u0440\u0443\u043a\u0442\u0443\u0440\u0430."),
    "aquarius": ("Teknoloji ve topluluk.", "Technology and community.", "\u0422\u0435\u0445\u043d\u043e\u043b\u043e\u0433\u0438\u0438 \u0438 \u0441\u043e\u043e\u0431\u0449\u0435\u0441\u0442\u0432\u043e."),
    "pisces": ("Sanat ve \u015fifa.", "Art and healing.", "\u0418\u0441\u043a\u0443\u0441\u0441\u0442\u0432\u043e \u0438 \u0438\u0441\u0446\u0435\u043b\u0435\u043d\u0438\u0435."),
}
for sid, vals in careers.items():
    add(f"birth.career.{sid}", *vals)

body = "/// Generated Y\u0131ld\u0131zname insight + trait presentation \u2014 TR / EN / RU.\nlibrary;\n\nimport '../l10n_triple.dart';\n\nconst kL10nBirthInsight = <String, L10nTriple>{\n" + "\n".join(rows) + "\n};\n"
W("lib/core/l10n/tables/table_birth_insight.dart", body)

# register
P("lib/core/l10n/app_string_tables.dart",
  "import 'tables/table_birth_more.dart';",
  "import 'tables/table_birth_more.dart';\nimport 'tables/table_birth_insight.dart';")
P("lib/core/l10n/app_string_tables.dart",
  "    ...kL10nBirthMore,",
  "    ...kL10nBirthMore,\n    ...kL10nBirthInsight,")

print("table ok", "Güneş" in body or "G\u00fcne\u015f" in body)
print("sample", [r for r in rows if "planet.sun" in r][0])
