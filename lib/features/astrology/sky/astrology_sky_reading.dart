/// Writes a daily reading from one person's transits (Turkish).
///
/// Each lane is built from a different calculated aspect, so love, work and
/// money never retell the same sentence. A lane with no aspect of its own
/// says so and speaks from that person's natal sign positions instead.
library;

import '../../birth_chart/models/zodiac_sign_id.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../models/astrology_daily_reading.dart';
import 'astrology_natal_sky.dart';
import 'astrology_sky_copy_tr.dart';
import 'astrology_transit_engine.dart';

abstract final class AstrologySkyReading {
  AstrologySkyReading._();

  static AstrologyDailyReading compose({
    required TransitSky sky,
    required DateTime day,
    List<String> themes = const [],
  }) {
    final natal = sky.natal;
    final seed = _dayIndex(day) + natal.of(SkyPoint.sun)!.longitude.floor();
    final used = <String>{};

    TransitHit? pick(bool Function(TransitHit h) wanted) {
      for (final h in sky.hits) {
        if (!wanted(h) || used.contains(h.key)) continue;
        used.add(h.key);
        return h;
      }
      return null;
    }

    final top = pick((_) => true);
    final loveHit = pick(_isLove);
    final careerHit = pick(_isCareer);
    final moneyHit = pick(_isMoney);
    final moodHit = pick((h) =>
        h.transit == SkyPoint.moon || h.natal.point == SkyPoint.moon);
    final driveHit = pick((h) =>
        h.transit == SkyPoint.mars || h.natal.point == SkyPoint.mars);
    final openHit = pick((h) => h.tone == TransitTone.flow);
    final hardHit = pick((h) => h.tone == TransitTone.friction);

    var love = loveHit != null
        ? _join([
            _fact(loveHit, lead: false),
            _pool(AstrologySkyCopyTr.love, loveHit.tone, seed + 1),
          ])
        : _quietLove(sky);
    var career = careerHit != null
        ? _join([
            _isReturn(careerHit)
                ? _fact(careerHit)
                : 'İş tarafında ${_fact(careerHit, lead: false)}',
            _pool(AstrologySkyCopyTr.career, careerHit.tone, seed + 2),
          ])
        : _quietCareer(sky);
    final money = moneyHit != null
        ? _join([
            'Para tarafında belirleyici olan, ${_made(moneyHit)}.',
            _pool(AstrologySkyCopyTr.money, moneyHit.tone, seed + 3),
          ])
        : _quietMoney(sky);

    final echo = _themeEcho(themes);
    if (echo != null) {
      if (echo.$1 == _Lane.love && loveHit != null) {
        love = _join([love, echo.$2]);
      } else if (echo.$1 == _Lane.career && careerHit != null) {
        career = _join([career, echo.$2]);
      }
    }

    return AstrologyDailyReading(
      personality: _portrait(natal),
      overall: top != null ? _overall(top, seed) : _quietOverall(sky),
      love: love,
      career: career,
      money: money,
      emotion: moodHit != null ? _mood(moodHit, seed + 4) : _quietMood(sky),
      energy: driveHit != null ? _drive(driveHit) : _quietDrive(sky),
      opportunity: openHit != null
          ? 'Bugünün açık kapısı, ${_made(openHit)}: '
              '${AstrologySkyCopyTr.opportunity[openHit.natal.point]} için '
              'elverişli bir zaman.'
          : AstrologySkyCopyTr.quietOpportunity,
      caution: hardHit != null
          ? 'Dikkat isteyen nokta, ${_made(hardHit)}: '
              '${AstrologySkyCopyTr.caution[hardHit.natal.point]}.'
          : AstrologySkyCopyTr.quietCaution,
      advice: top != null
          ? AstrologySkyCopyTr.reflection[top.tone]!
          : AstrologySkyCopyTr.quietReflection,
      innerTheme: themes.isEmpty
          ? PersonalThemeCopy.insufficient
          : PersonalThemeCopy.crossModal(themes),
      lovePersonal: true,
      careerPersonal: true,
      basis: natal.depth == NatalSkyDepth.full
          ? AstrologyReadingBasis.skyFull
          : AstrologyReadingBasis.skyDayOnly,
      basisNote: natal.depth == NatalSkyDepth.full
          ? AstrologySkyCopyTr.basisFull
          : AstrologySkyCopyTr.basisDayOnly,
    );
  }

  // ── Lane membership ────────────────────────────────────────────────

  static bool _isLove(TransitHit h) {
    const natal = {SkyPoint.venus, SkyPoint.moon, SkyPoint.mars};
    if (natal.contains(h.natal.point) && h.transit != SkyPoint.mercury) {
      return true;
    }
    return h.transit == SkyPoint.venus &&
        (h.natal.point == SkyPoint.sun || h.natal.point == SkyPoint.ascendant);
  }

  static bool _isCareer(TransitHit h) {
    const natal = {
      SkyPoint.sun,
      SkyPoint.midheaven,
      SkyPoint.saturn,
      SkyPoint.mercury,
    };
    const moving = {
      SkyPoint.sun,
      SkyPoint.mars,
      SkyPoint.jupiter,
      SkyPoint.saturn,
      SkyPoint.mercury,
    };
    if (natal.contains(h.natal.point) && moving.contains(h.transit)) {
      return true;
    }
    return h.natal.point == SkyPoint.mars &&
        (h.transit == SkyPoint.saturn || h.transit == SkyPoint.jupiter);
  }

  static bool _isMoney(TransitHit h) {
    const moving = {SkyPoint.venus, SkyPoint.jupiter, SkyPoint.saturn};
    const natal = {
      SkyPoint.venus,
      SkyPoint.jupiter,
      SkyPoint.saturn,
      SkyPoint.mercury,
    };
    return moving.contains(h.transit) && natal.contains(h.natal.point);
  }

  // ── Sentences from a hit ───────────────────────────────────────────

  /// "Mars bugün doğum haritandaki Venüs ile gergin bir kare açı yapıyor."
  static bool _isReturn(TransitHit h) =>
      h.transit == h.natal.point && h.aspect == TransitAspect.conjunction;

  static String _fact(TransitHit h, {bool lead = true}) {
    final t = AstrologySkyCopyTr.name[h.transit]!;
    if (_isReturn(h)) {
      if (h.transit == SkyPoint.sun) return AstrologySkyCopyTr.solarReturn;
      return '$t, doğduğun günkü konumunun üzerinden geçiyor.';
    }
    final when = lead ? ' bugün' : '';
    return '$t$when doğum haritandaki ${AstrologySkyCopyTr.name[h.natal.point]} '
        'ile ${AstrologySkyCopyTr.aspectVerb[h.aspect]}.';
  }

  /// "Jüpiter'in haritandaki Venüs ile yaptığı üçgen açı"
  static String _made(TransitHit h) =>
      '${AstrologySkyCopyTr.genitive[h.transit]} haritandaki '
      '${AstrologySkyCopyTr.name[h.natal.point]} ile yaptığı '
      '${AstrologySkyCopyTr.aspectNoun[h.aspect]}';

  /// "Mars'ın enerjisi, sevgiyi … biçimine sabırsızlık ve sürtünme katıyor."
  static String _colour(TransitHit h) =>
      '${AstrologySkyCopyTr.influence[h.transit]}, '
      '${AstrologySkyCopyTr.meaningDative[h.natal.point]} '
      '${AstrologySkyCopyTr.adds[h.transit]![h.tone]} katıyor.';

  static String _overall(TransitHit h, int seed) => _join([
        _fact(h),
        _colour(h),
        _pool(AstrologySkyCopyTr.general, h.tone, seed),
        AstrologySkyCopyTr.duration[h.transit]!,
      ]);

  static String _mood(TransitHit h, int seed) => _join([
        _fact(h),
        'Bu, ${AstrologySkyCopyTr.meaningDative[h.natal.point]} doğrudan '
            'dokunuyor; ${_pool(AstrologySkyCopyTr.mood, h.tone, seed)}',
      ]);

  static String _drive(TransitHit h) => _join([
        _fact(h),
        _colour(h),
        AstrologySkyCopyTr.duration[h.transit]!,
      ]);

  // ── Lanes without an aspect of their own ───────────────────────────

  static String _quietOverall(TransitSky sky) {
    final moon = sky.signOf(SkyPoint.moon);
    final sun = sky.natal.sunSign;
    return _join([
      'Bugün haritana doğrudan dokunan güçlü bir açı yok; gün daha çok '
          'kendi temponla akıyor.',
      _moonAgainstSun(moon, sun),
      AstrologySkyCopyTr.emotionRelation[relationOf(moon, sun)]!,
    ]);
  }

  static String _quietLove(TransitSky sky) {
    final now = sky.signOf(SkyPoint.venus);
    final natal = sky.natal.of(SkyPoint.venus)!.sign;
    return _join([
      AstrologySkyCopyTr.quietLove,
      'Venüs bugün ${AstrologySkyCopyTr.signLocative[now]}; doğum '
          'haritandaki Venüs ise ${AstrologySkyCopyTr.signLocative[natal]}.',
      AstrologySkyCopyTr.loveRelation[relationOf(now, natal)]!,
      ?_house(sky, SkyPoint.venus),
    ]);
  }

  static String _quietCareer(TransitSky sky) {
    final now = sky.signOf(SkyPoint.mercury);
    final natal = sky.natal.of(SkyPoint.mercury)!.sign;
    return _join([
      AstrologySkyCopyTr.quietCareer,
      'Merkür bugün ${AstrologySkyCopyTr.signLocative[now]}; doğum '
          'haritandaki Merkür ise ${AstrologySkyCopyTr.signLocative[natal]}.',
      AstrologySkyCopyTr.careerRelation[relationOf(now, natal)]!,
      ?_house(sky, SkyPoint.sun),
    ]);
  }

  static String _quietMoney(TransitSky sky) {
    final now = sky.signOf(SkyPoint.jupiter);
    final venus = sky.natal.of(SkyPoint.venus)!.sign;
    return _join([
      AstrologySkyCopyTr.quietMoney,
      'Jüpiter ${AstrologySkyCopyTr.signLocative[now]} ilerliyor; senin '
          'para ve değer anlayışını taşıyan Venüs ise '
          '${AstrologySkyCopyTr.signLocative[venus]}.',
      AstrologySkyCopyTr.moneyRelation[relationOf(now, venus)]!,
      ?_house(sky, SkyPoint.jupiter),
    ]);
  }

  static String _quietMood(TransitSky sky) {
    final now = sky.signOf(SkyPoint.moon);
    final natalMoon = sky.natal.moonSign;
    if (natalMoon != null) {
      return _join([
        'Ay bugün ${AstrologySkyCopyTr.signLocative[now]}; doğum haritanda '
            'Ay ${AstrologySkyCopyTr.signLocative[natalMoon]}.',
        AstrologySkyCopyTr.emotionRelation[relationOf(now, natalMoon)]!,
      ]);
    }
    final sun = sky.natal.sunSign;
    return _join([
      _moonAgainstSun(now, sun),
      AstrologySkyCopyTr.emotionRelation[relationOf(now, sun)]!,
    ]);
  }

  static String _quietDrive(TransitSky sky) {
    final now = sky.signOf(SkyPoint.mars);
    final natal = sky.natal.of(SkyPoint.mars)!.sign;
    return _join([
      'Mars bugün ${AstrologySkyCopyTr.signLocative[now]}; doğum '
          'haritandaki Mars ise ${AstrologySkyCopyTr.signLocative[natal]}.',
      AstrologySkyCopyTr.energyRelation[relationOf(now, natal)]!,
    ]);
  }

  /// "Venüs bugün doğum haritanın para ve kaynaklarla ilgili 2. evinden
  /// geçiyor." Only for a chart with a calculated ascendant.
  static String? _house(TransitSky sky, SkyPoint transit) {
    final house = sky.houseOf(transit);
    if (house == null) return null;
    return '${AstrologySkyCopyTr.name[transit]} bugün doğum haritanın '
        '${AstrologySkyCopyTr.houseArea[house]} ilgili $house. evinden '
        'geçiyor.';
  }

  // ── Natal portrait ─────────────────────────────────────────────────

  static String _portrait(AstrologyNatalSky natal) {
    final loc = AstrologySkyCopyTr.signLocative;
    final nature = AstrologySkyCopyTr.elementNature;
    final sun = natal.sunSign;
    final moon = natal.moonSign;
    final asc = natal.ascendantSign;
    if (moon == null) {
      final venus = natal.of(SkyPoint.venus)!.sign;
      final mars = natal.of(SkyPoint.mars)!.sign;
      return _join([
        'Senin haritanda Güneş ${loc[sun]}, Venüs ${loc[venus]}, '
            'Mars ${loc[mars]}.',
        elementOf(venus) == elementOf(mars)
            ? 'Dışarıya ${nature[elementOf(sun)]} ile çıkıyorsun; sevgide de '
                'harekette de ${nature[elementOf(venus)]} belirleyici.'
            : 'Dışarıya ${nature[elementOf(sun)]} ile çıkıyorsun; sevgide '
                '${nature[elementOf(venus)]}, harekette '
                '${nature[elementOf(mars)]} belirleyici.',
      ]);
    }
    final same = elementOf(sun) == elementOf(moon);
    return _join([
      asc == null
          ? 'Senin haritanda Güneş ${loc[sun]}, Ay ${loc[moon]}.'
          : 'Senin haritanda Güneş ${loc[sun]}, Ay ${loc[moon]}, yükselen '
              '${loc[asc]}.',
      same
          ? 'Dışarıya gösterdiğinle içeride hissettiğin aynı kaynaktan '
              'besleniyor: ${nature[elementOf(sun)]}.'
          : 'Dışarıya ${nature[elementOf(sun)]} ile çıkıyorsun; içeride ise '
              '${nature[elementOf(moon)]} arıyorsun.',
      if (asc != null)
        elementOf(asc) == elementOf(sun)
            ? 'İlk izlenimin de aynı çizgide; insanlar seni ilk anda da '
                'böyle tanıyor.'
            : elementOf(asc) == elementOf(moon)
                ? 'İlk izlenimde, içeride taşıdığın bu yan daha görünür.'
                : 'İlk izlenimde ise ${nature[elementOf(asc)]} öne çıkıyor.',
    ]);
  }

  // ── Themes ─────────────────────────────────────────────────────────

  static (_Lane, String)? _themeEcho(List<String> themes) {
    for (final raw in themes) {
      final theme = DiscoveryTheme.resolve(raw);
      if (theme == null) continue;
      final lane = _loveThemes.contains(theme)
          ? _Lane.love
          : _careerThemes.contains(theme)
              ? _Lane.career
              : null;
      if (lane == null) continue;
      final label = _lowerTr(theme.localized);
      return (
        lane,
        AstrologySkyCopyTr.themeEcho.replaceAll('{theme}', label),
      );
    }
    return null;
  }

  static const _loveThemes = {
    DiscoveryTheme.love,
    DiscoveryTheme.relationship,
    DiscoveryTheme.communication,
  };

  static const _careerThemes = {
    DiscoveryTheme.career,
    DiscoveryTheme.money,
    DiscoveryTheme.decision,
    DiscoveryTheme.change,
    DiscoveryTheme.redirection,
  };

  // ── Helpers ────────────────────────────────────────────────────────

  static String _pool(
    Map<TransitTone, List<String>> pool,
    TransitTone tone,
    int seed,
  ) {
    final lines = pool[tone]!;
    return lines[seed.abs() % lines.length];
  }

  /// "Ay bugün Oğlak'ta, yani toprak elementinde; Güneş burcun Koç ise ateş."
  static String _moonAgainstSun(ZodiacSignId moon, ZodiacSignId sun) =>
      'Ay bugün ${AstrologySkyCopyTr.signLocative[moon]}, yani '
      '${AstrologySkyCopyTr.elementWord[elementOf(moon)]} elementinde; '
      'Güneş burcun ${sun.labelTr} ise '
      '${AstrologySkyCopyTr.elementWord[elementOf(sun)]}.';

  static String _lowerTr(String s) =>
      s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  static String _join(List<String> parts) =>
      parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' ');

  static int _dayIndex(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day)
          .difference(DateTime.utc(2000))
          .inDays;
}

enum _Lane { love, career }
