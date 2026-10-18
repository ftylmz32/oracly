/// Local Yıldızname portrait built only from the saved, calculated chart.
///
/// Every sentence is tied to a fact the ephemeris actually produced: Sun,
/// Moon and rising sign placements, the tightest aspect between personal
/// bodies, and the element balance. Facts that are ambiguous or unavailable
/// (for example the rising sign without a birth time) are simply left out.
/// Turkish only; other languages keep the existing archive copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../birth_chart/astronomy/astronomical_fact_certainty.dart';
import '../../birth_chart/astronomy/natal_aspect.dart';
import '../../birth_chart/astronomy/natal_body.dart';
import '../../birth_chart/astronomy/natal_chart_evidence.dart';
import '../../birth_chart/astronomy/natal_placement.dart';
import '../../birth_chart/models/chart_fidelity.dart';
import '../../birth_chart/models/zodiac_sign_id.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../copy/star_map_polish_copy.dart';
import '../presentation/reference/star_map_result_section.dart';

abstract final class StarMapChartPortrait {
  StarMapChartPortrait._();

  static String get heading => OraclyL10n.t('star.portrait.heading');

  /// Null when there is no usable Sun placement or the language is not
  /// Turkish; callers then keep their existing copy.
  static List<StarMapResultSection>? build(
    NatalChartEvidence? evidence, {
    List<String> themes = const [],
  }) {
    if (evidence == null) return null;
    final code = OraclyL10n.code;
    if (code == 'en' || code == 'ru') return null;
    final sun = _usable(evidence, NatalBody.sun);
    if (sun == null) return null;
    final moon = _usable(evidence, NatalBody.moon);
    final asc = evidence.ascendant;
    final ascSign = asc != null && asc.certainty == AstronomicalFactCertainty.exact
        ? asc.sign
        : null;
    final aspect = _tightestPersonalAspect(evidence);
    final venus = _usable(evidence, NatalBody.venus);
    final mars = _usable(evidence, NatalBody.mars);
    final bond = <String>[
      if (venus != null) '${_venusHead(venus.sign!)} ${_venusLove[venus.sign!]}',
      if (mars != null) '${_marsHead(mars.sign!)} ${_marsDrive[mars.sign!]}',
      if (venus != null && mars != null)
        _relation(_venusMars, _element(venus.sign!), _element(mars.sign!)),
    ];

    final core = <String>[
      '${_sunHead(sun.sign!)} ${_sunTrait[sun.sign!]}',
      if (moon != null) ...[
        '${_moonHead(moon.sign!)} ${_moonNeed[moon.sign!]}',
        _relation(_sunMoon, _element(sun.sign!), _element(moon.sign!)),
      ],
      if (ascSign != null) ...[
        '${_ascHead(ascSign)} ${_ascLook[ascSign]}',
        _relation(_sunAsc, _element(sun.sign!), _element(ascSign)),
      ],
    ];

    final balance = evidence.elementBalance;
    final counts = <ChartElement, int>{
      ChartElement.fire: balance.fire,
      ChartElement.earth: balance.earth,
      ChartElement.air: balance.air,
      ChartElement.water: balance.water,
    };
    // Element balance is only meaningful when every body was calculated; a
    // reduced chart counts too few placements, and a "weak" element must not
    // contradict the reader's own Sun, Moon or rising sign.
    final full = evidence.fidelity == ChartCalculationFidelity.fullNatalEphemeris;
    final own = {
      _element(sun.sign!),
      if (moon != null) _element(moon.sign!),
      if (ascSign != null) _element(ascSign),
    };
    final dominant = full ? _dominant(counts) : null;
    final weakRaw = full ? _weakest(counts) : null;
    final weak = weakRaw != null && !own.contains(weakRaw) ? weakRaw : null;
    final tension = <String>[
      if (dominant != null) _dominantLine[dominant]!,
      if (weak != null && weak != dominant) _weakLine[weak]!,
      if (aspect != null) _aspectLine(aspect),
    ];

    return [
      StarMapResultSection(
        title: OraclyL10n.t('star.portrait.core'),
        body: core.join(' '),
      ),
      if (bond.isNotEmpty)
        StarMapResultSection(
          title: OraclyL10n.t('star.portrait.bond'),
          body: bond.join(' '),
        ),
      if (tension.isNotEmpty)
        StarMapResultSection(
          title: OraclyL10n.t('star.portrait.tension'),
          body: tension.join(' '),
        ),
      if (themes.isNotEmpty)
        StarMapResultSection(
          title: StarMapPolishCopy.journeyTitle,
          body: PersonalThemeCopy.crossModal(themes),
        ),
      StarMapResultSection(
        title: StarMapPolishCopy.leftQuestionTitle,
        body: _question(sun.sign!, moon?.sign, aspect, dominant),
      ),
    ];
  }

  /// Only the Sun sign is known (no calculated chart yet): an honest
  /// sun-only portrait plus what birth time and place would add.
  static List<StarMapResultSection>? fromSun(ZodiacSignId? sun) {
    final code = OraclyL10n.code;
    if (code == 'en' || code == 'ru') return null;
    if (sun == null) {
      return [
        StarMapResultSection(
          title: OraclyL10n.t('star.portrait.core'),
          body:
              'Yıldızname, doğum tarihin, saatin ve yerinle hesaplanan haritandan sana özel bir portre çıkarır. Doğum bilgilerini eklediğinde burada Güneş’in, Ay’ın ve diğer yerleşimlerinin birlikte seni nasıl anlattığı belirecek.',
        ),
      ];
    }
    return [
      StarMapResultSection(
        title: OraclyL10n.t('star.portrait.core'),
        body:
            '${_sunHead(sun)} ${_sunTrait[sun]} Doğum saatini ve yerini eklediğinde Ay’ın, yükselen burcunun ve diğer yerleşimlerinin bu çizgiyi nasıl desteklediğini ya da zorladığını da okuyabiliriz.',
      ),
      StarMapResultSection(
        title: StarMapPolishCopy.leftQuestionTitle,
        body: _question(sun, null, null, _element(sun)),
      ),
    ];
  }

  static NatalPlacement? _usable(NatalChartEvidence e, NatalBody body) {
    for (final p in e.placements) {
      if (p.body != body || p.sign == null) continue;
      if (p.certainty == AstronomicalFactCertainty.exact ||
          p.certainty == AstronomicalFactCertainty.intervalStable) {
        return p;
      }
    }
    return null;
  }

  static const _personal = {
    NatalBody.sun,
    NatalBody.moon,
    NatalBody.mercury,
    NatalBody.venus,
    NatalBody.mars,
  };

  static NatalAspect? _tightestPersonalAspect(NatalChartEvidence e) {
    NatalAspect? best;
    for (final a in e.aspects) {
      if (!_personal.contains(a.bodyA) || !_personal.contains(a.bodyB)) {
        continue;
      }
      // Mercury never strays far from the Sun; their bond says little.
      if ({a.bodyA, a.bodyB}.containsAll({NatalBody.sun, NatalBody.mercury})) {
        continue;
      }
      if (a.certainty != AstronomicalFactCertainty.exact &&
          a.certainty != AstronomicalFactCertainty.intervalStable) {
        continue;
      }
      if (best == null || a.orb.abs() < best.orb.abs()) best = a;
    }
    return best;
  }

  static ChartElement _element(ZodiacSignId s) => switch (s) {
        ZodiacSignId.aries ||
        ZodiacSignId.leo ||
        ZodiacSignId.sagittarius =>
          ChartElement.fire,
        ZodiacSignId.taurus ||
        ZodiacSignId.virgo ||
        ZodiacSignId.capricorn =>
          ChartElement.earth,
        ZodiacSignId.gemini ||
        ZodiacSignId.libra ||
        ZodiacSignId.aquarius =>
          ChartElement.air,
        ZodiacSignId.cancer ||
        ZodiacSignId.scorpio ||
        ZodiacSignId.pisces =>
          ChartElement.water,
      };

  /// same · support (fire–air, earth–water) · clash (fire–water,
  /// earth–air) · tempo (fire–earth, air–water).
  static String _relation(Map<String, String> table, ChartElement a, ChartElement b) {
    if (a == b) return table['same']!;
    final pair = {a, b};
    bool has(ChartElement x, ChartElement y) =>
        pair.contains(x) && pair.contains(y);
    if (has(ChartElement.fire, ChartElement.air) ||
        has(ChartElement.earth, ChartElement.water)) {
      return table['support']!;
    }
    if (has(ChartElement.fire, ChartElement.water) ||
        has(ChartElement.earth, ChartElement.air)) {
      return table['clash']!;
    }
    return table['tempo']!;
  }

  static ChartElement? _dominant(Map<ChartElement, int> c) {
    final total = c.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return null;
    final sorted = c.entries.toList()..sort((a, b) => b.value - a.value);
    if (sorted[0].value == sorted[1].value) return null;
    return sorted[0].key;
  }

  static ChartElement? _weakest(Map<ChartElement, int> c) {
    final total = c.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return null;
    final sorted = c.entries.toList()..sort((a, b) => a.value - b.value);
    if (sorted[0].value == sorted[1].value) return null;
    if (sorted[0].value * 4 > total) return null;
    return sorted[0].key;
  }

  static String _sunHead(ZodiacSignId s) => 'Güneşin ${s.labelTr} burcunda.';
  static String _moonHead(ZodiacSignId s) => 'Ay’ın ${s.labelTr} burcunda.';
  static String _ascHead(ZodiacSignId s) => 'Yükselen burcun ${s.labelTr}.';
  static String _venusHead(ZodiacSignId s) => 'Venüs’ün ${s.labelTr} burcunda.';
  static String _marsHead(ZodiacSignId s) => 'Mars’ın ${s.labelTr} burcunda.';

  static const _venusMars = {
    'same':
        'İstediğin şeyle onun peşinden gitme biçimin aynı yönde; bir şeyi gerçekten arzuladığında tereddüt etmeden ilerliyorsun.',
    'support':
        'Sevme biçiminle harekete geçme biçimin birbirini tamamlıyor; çekim duyduğun şeyi eyleme dökmekte zorlanmıyorsun.',
    'clash':
        'Arzuladığın şeyle onu elde etme biçimin farklı dillerden konuşuyor; bazen istediğin şeye yaklaşırken kendi yolunu kapatabiliyorsun.',
    'tempo':
        'Duygusal çekiminle harekete geçme hızın farklı tempoda; istediğin bir şey için ya çok erken ya da biraz geç adım atabiliyorsun.',
  };

  static const _venusLove = {
    ZodiacSignId.aries:
        'Sevgide hızlı ve doğrudansın; ilgini saklamak yerine göstermeyi seçiyorsun.',
    ZodiacSignId.taurus:
        'Sevgini istikrarla, dokunuşla ve emekle gösteriyorsun; güven senin için romantizmden önce geliyor.',
    ZodiacSignId.gemini:
        'Seni çeken şey önce zihin; iyi bir sohbet senin için en güçlü yakınlık biçimi.',
    ZodiacSignId.cancer:
        'Sevgide şefkatli ve koruyucusun; değer verdiğin insana yuva sıcaklığı sunuyorsun.',
    ZodiacSignId.leo:
        'Sevgide cömert ve tutkulusun; sevdiğini gururla gösteriyor, aynı coşkuyu karşılık olarak bekliyorsun.',
    ZodiacSignId.virgo:
        'Sevgini küçük ama özenli jestlerle, birinin hayatını kolaylaştırarak gösteriyorsun.',
    ZodiacSignId.libra:
        'İlişkide uyum, zarafet ve karşılıklılık arıyorsun; dengesizlik seni çabuk soğutuyor.',
    ZodiacSignId.scorpio:
        'Sevgide ya hep ya hiç diyorsun; yüzeysel bağlar sana yetmiyor, derin bir güven arıyorsun.',
    ZodiacSignId.sagittarius:
        'Sevgide özgürlük ve birlikte keşfetmek senin için önemli; seni kısıtlayan bağdan uzaklaşıyorsun.',
    ZodiacSignId.capricorn:
        'Sevgini sözden çok sorumlulukla gösteriyorsun; uzun soluklu ve güvenilir bağları seçiyorsun.',
    ZodiacSignId.aquarius:
        'Sevgide arkadaşlık ve alan senin için temel; birine en çok, seni olduğun gibi bıraktığında bağlanıyorsun.',
    ZodiacSignId.pisces:
        'Sevgide romantik ve fedakârsın; karşındakini idealleştirmeye yatkın bir kalbin var.',
  };

  static const _marsDrive = {
    ZodiacSignId.aries:
        'Harekete geçerken hızlı ve cesursun; beklemek seni en çok yoran şey.',
    ZodiacSignId.taurus:
        'Yavaş başlıyorsun ama bir kez yola çıktığında kolay kolay durmuyorsun.',
    ZodiacSignId.gemini:
        'Enerjin birden fazla işe dağılmaya yatkın; zihnin uyarıldığında en iyi işini çıkarıyorsun.',
    ZodiacSignId.cancer:
        'Duyguların seni harekete geçiriyor; sevdiklerini korumak söz konusu olduğunda beklenmedik bir güç gösteriyorsun.',
    ZodiacSignId.leo:
        'Yürekten ve görünür biçimde ilerliyorsun; takdir edildiğinde enerjin katlanıyor.',
    ZodiacSignId.virgo:
        'Enerjini planlı ve verimli kullanıyorsun; bir şeyi düzeltmek seni harekete geçiriyor.',
    ZodiacSignId.libra:
        'Harekete geçmeden önce tartıyorsun; doğrudan çatışmak yerine ikna ederek ilerliyorsun.',
    ZodiacSignId.scorpio:
        'Enerjin yoğun ve kararlı; bir hedefe kilitlendiğinde sessizce ama sonuna kadar gidiyorsun.',
    ZodiacSignId.sagittarius:
        'Seni harekete geçiren şey bir anlam ya da macera; inanmadığın bir işte zorlanıyorsun.',
    ZodiacSignId.capricorn:
        'Enerjini uzun vadeli hedeflere disiplinle yöneltiyorsun; sabır senin en güçlü yanın.',
    ZodiacSignId.aquarius:
        'Bir fikre ya da ideale inandığında harekete geçiyorsun; kurallara körü körüne uymak sana göre değil.',
    ZodiacSignId.pisces:
        'Enerjin dalgalı; ilhamla hareket ediyorsun ve zorlamak yerine akışı izlediğinde daha verimlisin.',
  };

  static const _bodyName = {
    NatalBody.sun: 'Güneş',
    NatalBody.moon: 'Ay',
    NatalBody.mercury: 'Merkür',
    NatalBody.venus: 'Venüs',
    NatalBody.mars: 'Mars',
  };

  static const _bodyTheme = {
    NatalBody.sun: 'kimliğin',
    NatalBody.moon: 'duygusal ihtiyaçların',
    NatalBody.mercury: 'düşünme biçimin',
    NatalBody.venus: 'sevme biçimin',
    NatalBody.mars: 'harekete geçme gücün',
  };

  static String _aspectLine(NatalAspect a) {
    final pair = '${_bodyName[a.bodyA]} ile ${_bodyName[a.bodyB]}';
    final x = _bodyTheme[a.bodyA]!;
    final y = _bodyTheme[a.bodyB]!;
    return switch (a.type) {
      AspectType.conjunction =>
        '$pair haritanda aynı noktada buluşuyor: $x ve $y birbirinden ayrılmaz biçimde birlikte çalışıyor; birini harekete geçiren şey çoğu zaman diğerini de harekete geçiriyor.',
      AspectType.trine =>
        '$pair arasındaki üçgen açı, $x ve $y arasında kolay bir akış kuruyor. Bu, çoğu zaman fark etmeden kullandığın bir yetenek; bilinçli kullandığında çok daha güçlü.',
      AspectType.sextile =>
        '$pair arasındaki sekstil, $x ve $y arasında küçük bir çabayla açılan bir kapı gibi; fırsat verdiğinde birbirini güzel tamamlıyorlar.',
      AspectType.square =>
        '$pair arasındaki kare açı, $x ve $y arasında sürtünme yaratıyor. Bu gerilim zaman zaman yorucu olabilir, ama seni harekete geçiren ve büyüten de çoğu zaman bu sürtünme.',
      AspectType.opposition =>
        '$pair karşı karşıya duruyor: $x ve $y arasında sürekli bir denge kurman gerekiyor. Birine fazla yaslandığında diğeri kendini hatırlatıyor.',
    };
  }

  static String _question(
    ZodiacSignId sun,
    ZodiacSignId? moon,
    NatalAspect? aspect,
    ChartElement? dominant,
  ) {
    if (aspect != null &&
        (aspect.type == AspectType.square ||
            aspect.type == AspectType.opposition)) {
      return '${_cap(_bodyTheme[aspect.bodyA]!)} ile ${_bodyTheme[aspect.bodyB]!} farklı yönlere çektiğinde, hangisini daha sık susturuyorsun?';
    }
    if (moon != null &&
        _relation(_kind, _element(sun), _element(moon)) == 'clash') {
      return 'İstediğin hayat ile ihtiyaç duyduğun huzur farklı yönlere çektiğinde, hangisini daha sık erteliyorsun?';
    }
    return switch (dominant) {
      ChartElement.fire =>
        'Başlattığın şeylerin kaçını gerçekten sonuna kadar götürmek istiyorsun?',
      ChartElement.earth =>
        'Kurduğun düzen seni koruyor mu, yoksa olduğun yerde mi tutuyor?',
      ChartElement.air =>
        'Kafanda bu kadar net olan şeyleri hayatına ne kadar taşıyorsun?',
      ChartElement.water =>
        'Başkalarının duygularını taşırken kendi duygularına ne kadar yer kalıyor?',
      null =>
        'Haritandaki bu çizgilerden hangisi sana en çok tanıdık geldi, hangisi seni şaşırttı?',
    };
  }

  static const _kind = {
    'same': 'same',
    'support': 'support',
    'clash': 'clash',
    'tempo': 'tempo',
  };

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static const _sunMoon = {
    'same':
        'Kim olduğunla neye ihtiyaç duyduğun aynı dili konuşuyor. Bu sana güçlü bir iç tutarlılık veriyor; tek risk, aynı yönde fazla ilerleyip dengeyi kaçırman.',
    'support':
        'Kimliğinle duygusal ihtiyaçların farklı ama birbirini besleyen yönlerden geliyor; biri diğerine nefes aldırıyor.',
    'clash':
        'Kim olmak istediğinle iç dünyanın neye ihtiyaç duyduğu her zaman aynı yöne çekmiyor. Yaşadığın kararsızlıkların bir kısmı bu iki sesin arasından geliyor olabilir; ama bu gerilim seni tek boyutlu olmaktan da koruyor.',
    'tempo':
        'Kimliğin bir hızda, duyguların başka bir hızda çalışıyor; bazen içinden geçenle yaptığın arasında bir gecikme hissedebilirsin. Bu farkı tanımak, ikisini de daha rahat kullanmanı sağlar.',
  };

  static const _sunAsc = {
    'same':
        'Dışarıya gösterdiğin yüz içindeki kimliğe çok yakın; insanlar seni gördükleri kadar tanıyor.',
    'support':
        'İlk izlenimin içindeki kimliği tamamlıyor; görünen halinle gerçek halin arasında doğal bir köprü var.',
    'clash':
        'İnsanların seni ilk gördüğü hal ile içindeki kimlik arasında belirgin bir fark var; seni ilk anda tanıdığını düşünenler zamanla bambaşka bir tarafını keşfediyor.',
    'tempo':
        'Dışarıya yansıyan temponla içindeki tempo aynı değil; insanlar seni olduğundan daha hızlı ya da daha yavaş sanabiliyor.',
  };

  static const _dominantLine = {
    ChartElement.fire:
        'Haritanda ateş ağır basıyor: harekete geçmek, başlatmak ve cesaret senin doğal kaynağın.',
    ChartElement.earth:
        'Haritanda toprak ağır basıyor: sabır, somut sonuç ve kalıcı bir şey kurma becerin güçlü.',
    ChartElement.air:
        'Haritanda hava ağır basıyor: düşünmek, bağ kurmak ve fikirleri dolaştırmak senin doğal alanın.',
    ChartElement.water:
        'Haritanda su ağır basıyor: sezgi, empati ve duygusal derinlik en güçlü kaynakların.',
  };

  static const _weakLine = {
    ChartElement.fire:
        'Ateşin az olması, ilk adımı atmak için bazen dışarıdan bir kıvılcım beklemene neden olabilir.',
    ChartElement.earth:
        'Toprağın az olması, fikirlerini somut adımlara dökmeyi zaman zaman zorlaştırabilir.',
    ChartElement.air:
        'Havanın az olması, hislerini kelimelere dökmekte ya da biraz mesafe alıp bakmakta zorlanmana yol açabilir.',
    ChartElement.water:
        'Suyun az olması, duygularını fark etmeyi ve göstermeyi ertelemene neden olabilir.',
  };

  static const _sunTrait = {
    ZodiacSignId.aries:
        'Kendini en canlı hissettiğin an, bir şeyi ilk başlatan kişi olduğun an.',
    ZodiacSignId.taurus:
        'Kimliğin emek verip sahiplendiğin şeylerle güçleniyor; yavaş ama kalıcı kuruyorsun.',
    ZodiacSignId.gemini:
        'Kendini merakın ve konuşmaların içinde buluyorsun; zihnin hareket ettikçe canlanıyorsun.',
    ZodiacSignId.cancer:
        'Kimliğinin merkezinde aidiyet var; değer verdiğin insanları kollarken kendini de buluyorsun.',
    ZodiacSignId.leo:
        'Kendini ortaya koyduğunda, yaratıp paylaştığında parlıyorsun; görülmek senin için gerçek bir ihtiyaç.',
    ZodiacSignId.virgo:
        'Bir şeyi düzeltip iyileştirdiğinde, gerçekten işe yaradığında kendini değerli hissediyorsun.',
    ZodiacSignId.libra:
        'Kimliğini ilişkiler içinde, denge ve uyum kurarak tanıyorsun.',
    ZodiacSignId.scorpio:
        'Yüzeyde kalan hiçbir şey seni tatmin etmiyor; kimliğin derinlik ve yoğunlukla şekilleniyor.',
    ZodiacSignId.sagittarius:
        'Kendini anlam ararken, yeni ufuklara doğru yol alırken buluyorsun.',
    ZodiacSignId.capricorn:
        'Kimliğin sorumluluk aldığın ve uzun vadede inşa ettiğin şeylerle şekilleniyor.',
    ZodiacSignId.aquarius:
        'Kendini farklı düşünebildiğinde, kalıpların dışına çıkabildiğinde özgür hissediyorsun.',
    ZodiacSignId.pisces:
        'Kimliğin sezgi ve hayal gücüyle örülü; sınırları belirsiz ama derin bir iç dünyan var.',
  };

  static const _moonNeed = {
    ZodiacSignId.aries:
        'Duygusal olarak hızlı tepki veriyorsun; içindeki rahatsızlığı uzun süre taşıyamıyor, hemen bir şey yapmak istiyorsun.',
    ZodiacSignId.taurus:
        'Güvende hissetmek için istikrara, tanıdık ritimlere ve somut yakınlığa ihtiyaç duyuyorsun.',
    ZodiacSignId.gemini:
        'Duygularını konuşarak ve anlatarak düzenliyorsun; susmak seni içten içe sıkıştırıyor.',
    ZodiacSignId.cancer:
        'Duygusal hafızan güçlü; kendini ancak gerçekten ait hissettiğin yerde rahat bırakıyorsun.',
    ZodiacSignId.leo:
        'İçten içe sevildiğini ve fark edildiğini bilmeye ihtiyaç duyuyorsun; sıcaklık seni hemen toparlıyor.',
    ZodiacSignId.virgo:
        'Duygularını düzen kurarak yönetiyorsun; kaygılandığında bir şeyleri toparlamak seni sakinleştiriyor.',
    ZodiacSignId.libra:
        'Huzursuzluk seni çabuk etkiliyor; iç dengen çoğu zaman ilişkilerindeki dengeye bağlı.',
    ZodiacSignId.scorpio:
        'Duyguların derin ve yoğun; güvenmeden açılmıyor, açıldığında ise tüm kalbinle bağlanıyorsun.',
    ZodiacSignId.sagittarius:
        'Duygusal olarak alana ve hareket özgürlüğüne ihtiyacın var; sıkıştığını hissedince uzaklaşmak istiyorsun.',
    ZodiacSignId.capricorn:
        'Duygularını kontrol altında tutmayı seçiyorsun; kırılganlığını göstermek sana zor geliyor.',
    ZodiacSignId.aquarius:
        'Duygularına biraz mesafeden bakıyorsun; önce anlamak, sonra hissetmek istiyorsun.',
    ZodiacSignId.pisces:
        'Çevrendeki duyguları büyük bir hassasiyetle içine alıyorsun; yalnız kalmak seni arındırıyor.',
  };

  static const _ascLook = {
    ZodiacSignId.aries:
        'İnsanlar seni ilk anda enerjik, doğrudan ve cesur biri olarak görüyor.',
    ZodiacSignId.taurus:
        'İlk izlenimde sakin, güven veren ve ağırbaşlı birisin.',
    ZodiacSignId.gemini:
        'Dışarıdan hareketli, meraklı ve sohbeti kolay biri gibi görünüyorsun.',
    ZodiacSignId.cancer:
        'İlk anda yumuşak, koruyucu ve biraz çekingen bir hava veriyorsun.',
    ZodiacSignId.leo:
        'Bir ortama girdiğinde fark ediliyorsun; sıcak ve kendinden emin bir duruşun var.',
    ZodiacSignId.virgo:
        'Dışarıdan dikkatli, düzenli ve ölçülü biri olarak algılanıyorsun.',
    ZodiacSignId.libra:
        'İlk izlenimde zarif, nazik ve uyumlu bir duruşun var.',
    ZodiacSignId.scorpio:
        'Dışarıdan sakin ama yoğun bir varlığın var; insanlar seni hemen çözemiyor.',
    ZodiacSignId.sagittarius:
        'İlk anda açık, neşeli ve özgür ruhlu biri gibi görünüyorsun.',
    ZodiacSignId.capricorn:
        'Dışarıdan ciddi, olgun ve kontrollü bir izlenim bırakıyorsun.',
    ZodiacSignId.aquarius:
        'İlk anda farklı, bağımsız ve biraz mesafeli bir hava veriyorsun.',
    ZodiacSignId.pisces:
        'Dışarıdan yumuşak, dalgın ve anlayışlı biri olarak görünüyorsun.',
  };
}
