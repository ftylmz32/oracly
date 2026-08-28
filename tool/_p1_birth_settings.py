# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r"C:\Dev\oracly_new")


def write(rel: str, text: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8", newline="\n")
    print("wrote", rel)


def patch(rel: str, old: str, new: str) -> None:
    p = ROOT / rel
    t = p.read_text(encoding="utf-8")
    if old not in t:
        raise SystemExit(f"MISSING in {rel}:\n{old[:160]!r}")
    p.write_text(t.replace(old, new, 1), encoding="utf-8", newline="\n")
    print("patched", rel)


# Fix corrupted dream.new
dream = (ROOT / "lib/core/l10n/tables/table_dream.dart").read_text(encoding="utf-8")
import re

dream2, n = re.subn(
    r"'dream\.new': L10nTriple\([^)]+\),",
    "'dream.new': L10nTriple('Yeni rüya', 'New dream', 'Новый сон'),",
    dream,
    count=1,
)
if n != 1:
    raise SystemExit(f"dream.new replace failed n={n}")
(ROOT / "lib/core/l10n/tables/table_dream.dart").write_text(
    dream2, encoding="utf-8", newline="\n"
)
print("fixed dream.new")

# Settings: live entitlement
patch(
    "lib/screens/settings/reference/settings_reference_screen.dart",
    """import '../../../features/home/reference/home_reference_background.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../profile/data/profile_photo_store.dart';""",
    """import '../../../features/home/reference/home_reference_background.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../features/premium/providers/premium_providers.dart';
import '../../profile/data/profile_photo_store.dart';""",
)
patch(
    "lib/screens/settings/reference/settings_reference_screen.dart",
    """  String _profileName = '';
  bool _profilePremium = false;
  Future<void> _write = Future.value();""",
    """  String _profileName = '';
  Future<void> _write = Future.value();""",
)
patch(
    "lib/screens/settings/reference/settings_reference_screen.dart",
    """    final profile = await ref.read(userRepositoryProvider).getProfile();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _profileName = profile.name;
      _profilePremium = profile.isPremium;
    });
      _loading = false;
    });""",
    """    final profile = await ref.read(userRepositoryProvider).getProfile();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _profileName = profile.name;
      _loading = false;
    });""",
)
patch(
    "lib/screens/settings/reference/settings_reference_screen.dart",
    """    ref.watch(appLocaleProvider);
    ref.watch(appThemeModeProvider);
    final lang = AppLocale.normalize(_settings.language);
    final settingsForUi = _settings.copyWith(language: lang);
    final photo = ref.watch(profilePhotoProvider);""",
    """    ref.watch(appLocaleProvider);
    ref.watch(appThemeModeProvider);
    final premiumStatus = ref.watch(premiumStatusProvider);
    final lang = AppLocale.normalize(_settings.language);
    final settingsForUi = _settings.copyWith(language: lang);
    final photo = ref.watch(profilePhotoProvider);
    // Prefer live entitlement; avoid flashing Free while first reconcile runs
    // if we already know Premium from a prior active session in-memory.
    final profilePremium = premiumStatus.isPremium;""",
)
patch(
    "lib/screens/settings/reference/settings_reference_screen.dart",
    """              profileName: _profileName,
              profilePremium: _profilePremium,
              profilePhoto: photo,""",
    """              profileName: _profileName,
              profilePremium: profilePremium,
              profilePhoto: photo,""",
)

# Planet + aspect labeled()
patch(
    "lib/features/birth_chart/models/zodiac_sign_id.dart",
    """  const PlanetId(this.labelTr);
  final String labelTr;
}""",
    """  const PlanetId(this.labelTr);
  final String labelTr;

  String labeled(String languageCode) =>
      OraclyL10n.t('planet.$name', languageCode: languageCode);
}""",
)
patch(
    "lib/features/birth_chart/models/zodiac_sign_id.dart",
    """  const AspectType(this.labelTr, this.angle, this.defaultOrb);
  final String labelTr;
  final int angle;
  final int defaultOrb;
}""",
    """  const AspectType(this.labelTr, this.angle, this.defaultOrb);
  final String labelTr;
  final int angle;
  final int defaultOrb;

  String labeled(String languageCode) =>
      OraclyL10n.t('aspect.$name', languageCode: languageCode);
}""",
)

write(
    "lib/core/l10n/tables/table_birth_insight.dart",
    r'''/// Generated Yıldızname insight + trait presentation — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nBirthInsight = <String, L10nTriple>{
  'birth.conj_and': L10nTriple('ve', 'and', 'и'),
  'birth.element.fire': L10nTriple('Ateş', 'Fire', 'Огонь'),
  'birth.element.earth': L10nTriple('Toprak', 'Earth', 'Земля'),
  'birth.element.air': L10nTriple('Hava', 'Air', 'Воздух'),
  'birth.element.water': L10nTriple('Su', 'Water', 'Вода'),
  'birth.energy.label': L10nTriple(
    '{element} Güneş',
    '{element} Sun',
    'Солнце {element}',
  ),
  'birth.energy.summary': L10nTriple(
    '{sign} Güneşi, {element} elementinin tonunu taşır. Ay, Yükselen ve evler gerçek bir hesap kaynağı bağlanınca eklenecek.',
    'The {sign} Sun carries the tone of the {element} element. Moon, Rising, and houses will be added when a real calculation source is connected.',
    'Солнце в знаке {sign} несёт тон стихии {element}. Луна, Асцендент и дома появятся при подключении реального расчёта.',
  ),
  'birth.result.summary': L10nTriple(
    '{sign} Güneşi, {energy} tonunu taşır. {ephemeris}',
    'The {sign} Sun carries a {energy} tone. {ephemeris}',
    'Солнце в знаке {sign} несёт тон: {energy}. {ephemeris}',
  ),
  'birth.result.strong_fallback': L10nTriple(
    '{sign} Güneşinin bilinen güçlü yanı, görünür kimliğini sakin tutmaktır.',
    'A known strength of the {sign} Sun is keeping visible identity calm.',
    'Известная сила Солнца в знаке {sign} — спокойно держать видимую идентичность.',
  ),
  'birth.house_of': L10nTriple('{n}. ev', '{n}. house', '{n}. дом'),
  'birth.placement.moon': L10nTriple(
    'Ay {sign}',
    'Moon in {sign}',
    'Луна в знаке {sign}',
  ),
  'birth.placement.rising': L10nTriple(
    'Yükselen {sign}',
    'Rising {sign}',
    'Асцендент {sign}',
  ),
  'birth.placement.planet': L10nTriple(
    '{planet} {sign}',
    '{planet} in {sign}',
    '{planet} в знаке {sign}',
  ),
  'birth.theme.identity': L10nTriple('Kimlik', 'Identity', 'Идентичность'),
  'birth.theme.identity_body': L10nTriple(
    '{sign} Güneşi, {traits} yanlarını öne çıkarmayı sevebilir.',
    'The {sign} Sun may enjoy bringing out {traits} sides.',
    'Солнце в знаке {sign} может любить проявлять стороны: {traits}.',
  ),
  'birth.insight.sun_body': L10nTriple(
    '{sign} Güneşi, kimliğini {traits} bir tınıyla taşır. {glossary}',
    'The {sign} Sun carries identity with a {traits} tone. {glossary}',
    'Солнце в знаке {sign} несёт идентичность с тоном: {traits}. {glossary}',
  ),
  'birth.insight.moon_body': L10nTriple(
    'Ay {sign}, duygusal dünyanda {trait} bir ton bırakır. {glossary}',
    'Moon in {sign} leaves a {trait} tone in the emotional world. {glossary}',
    'Луна в знаке {sign} оставляет {trait} тон во внутреннем мире. {glossary}',
  ),
  'birth.insight.rising_body': L10nTriple(
    'Yükselen {sign}, ilk izlenimde {trait} bir kapı açar. {glossary}',
    'Rising {sign} opens a {trait} door at first impression. {glossary}',
    'Асцендент {sign} открывает {trait} дверь при первом впечатлении. {glossary}',
  ),
  'birth.insight.core_sun': L10nTriple(
    'Özün {sign} enerjisiyle {traits} bir tını taşıyor olabilir.',
    'Your core may carry a {traits} tone with {sign} energy.',
    'Суть может нести {traits} тон с энергией знака {sign}.',
  ),
  'birth.insight.core_moon': L10nTriple(
    'Ay {sign}, dinlenmeye ihtiyaç duyduğunda {trait} bir ton arayabileceğini düşündürür.',
    'Moon in {sign} suggests you may seek a {trait} tone when you need rest.',
    'Луна в знаке {sign} намекает, что в отдыхе ты можешь искать {trait} тон.',
  ),
  'birth.insight.core_rising': L10nTriple(
    'Yükselen {sign}, tanışıldığında {trait} bir izlenim bırakman mümkün.',
    'Rising {sign} may leave a {trait} impression when you are met.',
    'Асцендент {sign} может оставлять {trait} впечатление при знакомстве.',
  ),
  'planet.sun': L10nTriple('Güneş', 'Sun', 'Солнце'),
  'planet.moon': L10nTriple('Ay', 'Moon', 'Луна'),
  'planet.ascendant': L10nTriple('Yükselen', 'Rising', 'Асцендент'),
  'planet.mercury': L10nTriple('Merkür', 'Mercury', 'Меркурий'),
  'planet.venus': L10nTriple('Venüs', 'Venus', 'Венера'),
  'planet.mars': L10nTriple('Mars', 'Mars', 'Марс'),
  'planet.jupiter': L10nTriple('Jüpiter', 'Jupiter', 'Юпитер'),
  'planet.saturn': L10nTriple('Satürn', 'Saturn', 'Сатурн'),
  'planet.uranus': L10nTriple('Uranüs', 'Uranus', 'Уран'),
  'planet.neptune': L10nTriple('Neptün', 'Neptune', 'Нептун'),
  'planet.pluto': L10nTriple('Plüton', 'Pluto', 'Плутон'),
  'aspect.conjunction': L10nTriple('Kavuşum', 'Conjunction', 'Соединение'),
  'aspect.sextile': L10nTriple('Sekstil', 'Sextile', 'Секстиль'),
  'aspect.square': L10nTriple('Kare', 'Square', 'Квадрат'),
  'aspect.trine': L10nTriple('Üçgen', 'Trine', 'Трин'),
  'aspect.opposition': L10nTriple('Karşıt', 'Opposition', 'Оппозиция'),
  'birth.trait.aries.0': L10nTriple('Cesur', 'Brave', 'Смелый'),
  'birth.trait.aries.1': L10nTriple('Girişken', 'Assertive', 'Инициативный'),
  'birth.trait.taurus.0': L10nTriple('Kararlı', 'Steady', 'Стойкий'),
  'birth.trait.taurus.1': L10nTriple('Güvenilir', 'Reliable', 'Надёжный'),
  'birth.trait.gemini.0': L10nTriple('Meraklı', 'Curious', 'Любопытный'),
  'birth.trait.gemini.1': L10nTriple('İletişimci', 'Communicative', 'Общительный'),
  'birth.trait.cancer.0': L10nTriple('Koruyucu', 'Protective', 'Заботливый'),
  'birth.trait.cancer.1': L10nTriple('Sezgisel', 'Intuitive', 'Интуитивный'),
  'birth.trait.leo.0': L10nTriple('Cömert', 'Generous', 'Щедрый'),
  'birth.trait.leo.1': L10nTriple('Yaratıcı', 'Creative', 'Творческий'),
  'birth.trait.virgo.0': L10nTriple('Analitik', 'Analytical', 'Аналитичный'),
  'birth.trait.virgo.1': L10nTriple('Düzenli', 'Orderly', 'Организованный'),
  'birth.trait.librai.0': L10nTriple('Diplomatik', 'Diplomatic', 'Дипломатичный'),
  'birth.trait.libra.0': L10nTriple('Diplomatik', 'Diplomatic', 'Дипломатичный'),
  'birth.trait.libra.1': L10nTriple('Adil', 'Fair', 'Справедливый'),
  'birth.trait.scorpio.0': L10nTriple('Derin', 'Deep', 'Глубокий'),
  'birth.trait.scorpio.1': L10nTriple('Kararlı', 'Determined', 'Решительный'),
  'birth.trait.sagittarius.0': L10nTriple('Özgür', 'Free', 'Свободный'),
  'birth.trait.sagittarius.1': L10nTriple('İyimser', 'Optimistic', 'Оптимистичный'),
  'birth.trait.capricorn.0': L10nTriple('Disiplinli', 'Disciplined', 'Дисциплинированный'),
  'birth.trait.capricorn.1': L10nTriple('Sorumlu', 'Responsible', 'Ответственный'),
  'birth.trait.aquarius.0': L10nTriple('Özgün', 'Original', 'Самобытный'),
  'birth.trait.aquarius.1': L10nTriple('İnsancıl', 'Humane', 'Гуманичный'),
  'birth.trait.pisces.0': L10nTriple('Empatik', 'Empathic', 'Эмпатичный'),
  'birth.trait.pisces.1': L10nTriple('Hayalperest', 'Imaginative', 'Мечтательный'),
  'birth.career.aries': L10nTriple(
    'Girişimci ve rekabetçi.',
    'Entrepreneurial and competitive.',
    'Предприимчивый и соревновательный.',
  ),
  'birth.career.taurus': L10nTriple(
    'İstikrarlı ve kalite odaklı.',
    'Steady and quality-focused.',
    'Стабильный и ориентированный на качество.',
  ),
  'birth.career.gemini': L10nTriple(
    'Çok yönlü ve hızlı öğrenen.',
    'Versatile and a quick learner.',
    'Многогранный и быстро обучающийся.',
  ),
  'birth.career.cancer': L10nTriple(
    'Besleyici ve destekleyici roller.',
    'Nurturing and supportive roles.',
    'Заботливые и поддерживающие роли.',
  ),
  'birth.career.leo': L10nTriple(
    'Sahne ve yaratıcı alanlar.',
    'Stage and creative fields.',
    'Сцена и творческие сферы.',
  ),
  'birth.career.virgo': L10nTriple(
    'Organizasyon ve uzmanlık.',
    'Organization and craft.',
    'Организация и мастерство.',
  ),
  'birth.career.libra': L10nTriple(
    'Arabuluculuk ve tasarım.',
    'Mediation and design.',
    'Посредничество и дизайн.',
  ),
  'birth.career.scorpio': L10nTriple(
    'Araştırma ve strateji.',
    'Research and strategy.',
    'Исследование и стратегия.',
  ),
  'birth.career.sagittarius': L10nTriple(
    'Eğitim ve keşif.',
    'Learning and exploration.',
    'Обучение и исследование.',
  ),
  'birth.career.capricorn': L10nTriple(
    'Yönetim ve yapı.',
    'Leadership and structure.',
    'Управление и структура.',
  ),
  'birth.career.aquarius': L10nTriple(
    'Teknoloji ve topluluk.',
    'Technology and community.',
    'Технологии и сообщество.',
  ),
  'birth.career.pisces': L10nTriple(
    'Sanat ve şifa.',
    'Art and healing.',
    'Искусство и исцеление.',
  ),
};
'''.replace(
        "  'birth.trait.librai.0': L10nTriple('Diplomatik', 'Diplomatic', 'Дипломатичный'),\n",
        "",
    ),
)

# Register table
patch(
    "lib/core/l10n/app_string_tables.dart",
    "import 'tables/table_birth_more.dart';",
    "import 'tables/table_birth_more.dart';\nimport 'tables/table_birth_insight.dart';",
)
patch(
    "lib/core/l10n/app_string_tables.dart",
    "    ...kL10nBirthMore,",
    "    ...kL10nBirthMore,\n    ...kL10nBirthInsight,",
)

write(
    "lib/features/birth_chart/services/chart_insight_locale.dart",
    r'''/// Locale helpers for generated birth-chart presentation copy.
library;

import '../../../core/l10n/l10n.dart';
import '../models/zodiac_sign_id.dart';

abstract final class ChartInsightLocale {
  ChartInsightLocale._();

  static String fill(String key, Map<String, String> vars) {
    var out = OraclyL10n.t(key);
    for (final entry in vars.entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out;
  }

  static String signName(ZodiacSignId sign) =>
      sign.labeled(OraclyL10n.code);

  static String elementName(ChartElement element) =>
      OraclyL10n.t('birth.element.${element.name}');

  static List<String> traits(ZodiacSignId sign) => [
        OraclyL10n.t('birth.trait.${sign.id}.0'),
        OraclyL10n.t('birth.trait.${sign.id}.1'),
      ];

  static String career(ZodiacSignId sign) =>
      OraclyL10n.t('birth.career.${sign.id}');

  static String joinAnd(List<String> parts) {
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    final conj = OraclyL10n.t('birth.conj_and');
    return '${parts.sublist(0, parts.length - 1).join(', ')} $conj ${parts.last}';
  }
}
''',
)

write(
    "lib/features/birth_chart/services/chart_insight_generator.dart",
    r'''/// Translates known placements into calm, locale-aware interpretations.
library;

import '../copy/birth_chart_copy.dart';
import '../models/birth_chart.dart';
import '../models/chart_insight.dart';
import '../models/life_theme.dart';
import '../models/zodiac_sign_id.dart';
import 'chart_insight_locale.dart';

class ChartInsightGenerator {
  const ChartInsightGenerator();

  List<ChartInsight> generate(BirthChart chart) {
    final sun = chart.sun.sign;
    final moon = chart.hasFullNatal ? chart.moon?.sign : null;
    final rising = chart.hasFullNatal ? chart.rising?.sign : null;
    return [
      _sunPlacement(sun),
      if (moon != null) _moonPlacement(moon),
      if (rising != null) _risingPlacement(rising),
      _corePersonality(sun, moon, rising),
      _lifeThemesInsight(chart),
    ];
  }

  List<LifeTheme> lifeThemes(BirthChart chart) {
    final sun = chart.sun.sign;
    final name = ChartInsightLocale.signName(sun);
    final traits = ChartInsightLocale.joinAnd(ChartInsightLocale.traits(sun));
    return [
      LifeTheme(
        id: 'identity',
        title: OraclyL10nKey.themeIdentity,
        body: ChartInsightLocale.fill('birth.theme.identity_body', {
          'sign': name,
          'traits': traits,
        }),
      ),
      LifeTheme(
        id: 'element',
        title: chart.dominantEnergy.label,
        body: chart.dominantEnergy.summary,
      ),
    ];
  }

  ChartInsight _sunPlacement(ZodiacSignId sun) {
    final name = ChartInsightLocale.signName(sun);
    final traits = ChartInsightLocale.joinAnd(ChartInsightLocale.traits(sun));
    return ChartInsight(
      kind: ChartInsightKind.bigThree,
      title: '${BirthChartCopy.sunLabel} — $name',
      body: ChartInsightLocale.fill('birth.insight.sun_body', {
        'sign': name,
        'traits': traits,
        'glossary': BirthChartCopy.sunGlossary,
      }),
      glossaryTerm: BirthChartCopy.sunLabel,
      glossaryExplanation: BirthChartCopy.sunGlossary,
    );
  }

  ChartInsight _moonPlacement(ZodiacSignId moon) {
    final name = ChartInsightLocale.signName(moon);
    final trait = ChartInsightLocale.traits(moon).first;
    return ChartInsight(
      kind: ChartInsightKind.emotionalPatterns,
      title: '${BirthChartCopy.moonLabel} — $name',
      body: ChartInsightLocale.fill('birth.insight.moon_body', {
        'sign': name,
        'trait': trait,
        'glossary': BirthChartCopy.moonGlossary,
      }),
      glossaryTerm: BirthChartCopy.moonLabel,
      glossaryExplanation: BirthChartCopy.moonGlossary,
    );
  }

  ChartInsight _risingPlacement(ZodiacSignId rising) {
    final name = ChartInsightLocale.signName(rising);
    final trait = ChartInsightLocale.traits(rising).first;
    return ChartInsight(
      kind: ChartInsightKind.strengths,
      title: '${BirthChartCopy.risingLabel} — $name',
      body: ChartInsightLocale.fill('birth.insight.rising_body', {
        'sign': name,
        'trait': trait,
        'glossary': BirthChartCopy.risingGlossary,
      }),
      glossaryTerm: BirthChartCopy.risingLabel,
      glossaryExplanation: BirthChartCopy.risingGlossary,
    );
  }

  ChartInsight _corePersonality(
    ZodiacSignId sun,
    ZodiacSignId? moon,
    ZodiacSignId? rising,
  ) {
    final sunName = ChartInsightLocale.signName(sun);
    final traits = ChartInsightLocale.joinAnd(ChartInsightLocale.traits(sun));
    final parts = <String>[
      ChartInsightLocale.fill('birth.insight.core_sun', {
        'sign': sunName,
        'traits': traits,
      }),
      ChartInsightLocale.career(sun),
    ];
    if (moon != null) {
      parts.add(
        ChartInsightLocale.fill('birth.insight.core_moon', {
          'sign': ChartInsightLocale.signName(moon),
          'trait': ChartInsightLocale.traits(moon).first,
        }),
      );
    }
    if (rising != null) {
      parts.add(
        ChartInsightLocale.fill('birth.insight.core_rising', {
          'sign': ChartInsightLocale.signName(rising),
          'trait': ChartInsightLocale.traits(rising).first,
        }),
      );
    }
    return ChartInsight(
      kind: ChartInsightKind.corePersonality,
      title: BirthChartCopy.corePersonalityTitle,
      body: parts.join('\n\n'),
    );
  }

  ChartInsight _lifeThemesInsight(BirthChart chart) {
    final themes = lifeThemes(chart);
    return ChartInsight(
      kind: ChartInsightKind.lifeThemes,
      title: BirthChartCopy.lifeThemesTitle,
      body: themes.map((t) => '${t.title}\n${t.body}').join('\n\n'),
    );
  }
}

/// Tiny alias so theme title stays on the l10n table without copy churn.
abstract final class OraclyL10nKey {
  static String get themeIdentity =>
      ChartInsightLocale.fill('birth.theme.identity', const {});
}
''',
)

print("core patches done")
