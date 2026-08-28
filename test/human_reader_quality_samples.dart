/// Sample readings for the 20-text humanness gate.
library;

import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

int someoneTokenHits(List<String> texts) {
  const tokens = [
    'kuş', 'yol', 'kalp', 'yüzük', 'koç', 'ikizler', 'akrep',
    'sınırlar', 'ilişki', 'değişim', 'duruluk',
  ];
  return texts.where((t) {
    final lower = t.toLowerCase();
    return tokens.any(lower.contains);
  }).length;
}

PersonalDiscoveryProfile _profile() {
  CrossDiscoveryInsight hit(String theme) => CrossDiscoveryInsight(
        theme: theme,
        sources: const ['tarot', 'coffee'],
        confidence: DiscoveryThemeStrength.recurring,
        lastObserved: DateTime(2026, 8, 17),
        sourceCount: 2,
        discoveryCount: 2,
        recencyWeight: 1,
      );
  return PersonalDiscoveryProfile(
    crossInsights: [hit('ilişki'), hit('kariyer'), hit('sınırlar')],
  );
}

CoffeeReading _cup(
  String id,
  List<String> names,
  String observation, {
  List<String> themes = const [],
}) {
  return CoffeeFortuneComposer.compose(
    CoffeeReading(
      id: id,
      createdAt: DateTime(2026, 8, 17),
      overall: 'iletişim ön plana çıkabilir',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
      visualObservation: observation,
      symbols: [for (final n in names) CoffeeSymbol(name: n, meaning: '', interpretation: '')],
    ),
    themes: themes,
  );
}

String _write({
  required int seed,
  required String seen,
  required String meaning,
  String name = '',
  String companion = '',
  String life = '',
  required String vessel,
  HumanReaderLength length = HumanReaderLength.brief,
}) {
  return HumanReader.write(
    HumanReaderNotice(
      seed: seed,
      name: name,
      seen: seen,
      companion: companion,
      meaning: meaning,
      lifeThread: life,
      vessel: vessel,
      length: length,
    ),
  );
}

List<String> twentyHumanReadings() {
  final profile = _profile();
  final aries = AstrologyContentCatalogue.signById('aries')!;
  final gemini = AstrologyContentCatalogue.signById('gemini')!;
  final scorpio = AstrologyContentCatalogue.signById('scorpio')!;
  final cups = [
    _cup('a', const ['kuş', 'yol'], 'Fincanda kuş ve yol.'),
    _cup('b', const ['kalp'], 'Kalp izi.'),
    _cup('c', const ['yüzük', 'kalp'], 'Yüzük kalple.'),
    _cup('d', const ['yol'], 'Açık yol.', themes: const ['değişim']),
    _cup('e', const [], 'Fincanda duruluk var.'),
  ];
  String sky(dynamic sign, DateTime day, [PersonalDiscoveryProfile? p]) =>
      AstrologyDailyReadingService.build(sign, now: day, profile: p).overall;
  return [
    for (final c in cups) c.overall,
    _cup('f', const ['dağ'], 'Dipte bir dağ izi.').overall,
    sky(aries, DateTime(2026, 8, 17), profile),
    AstrologyDailyReadingService.build(aries, now: DateTime(2026, 8, 17), profile: profile).love,
    sky(gemini, DateTime(2026, 8, 18), profile),
    AstrologyDailyReadingService.build(scorpio, now: DateTime(2026, 8, 19)).emotion,
    AstrologyDailyReadingService.build(aries, now: DateTime(2026, 8, 20), profile: profile).career,
    StarMapReadingService.build(now: DateTime(2026, 8, 17), sunSign: ZodiacSignId.aries, discovery: profile).todayReflection,
    StarMapReadingService.build(now: DateTime(2026, 8, 17), sunSign: ZodiacSignId.gemini, discovery: profile).skyMessage.today,
    StarMapReadingService.build(now: DateTime(2026, 8, 18), sunSign: ZodiacSignId.scorpio).overview.mainMessage,
    _write(seed: 11, name: 'Deniz', seen: 'kuş', companion: 'yol', meaning: 'Beklenen haber yolun ucunda duruyor.', life: 'değişim', vessel: HumanReader.vesselCup()),
    _write(seed: 22, seen: 'Koç', meaning: 'Tek görünür teslim, dağınık cesaretten ileri gider.', life: 'ilişki', vessel: HumanReader.vesselSky()),
    _write(seed: 33, seen: 'sınırlar', meaning: 'Son keşiflerinde sınırlar izi tekrar ediyor.', vessel: HumanReader.vesselChart(), length: HumanReaderLength.deep),
    sky(AstrologyContentCatalogue.signById('taurus')!, DateTime(2026, 8, 21)),
    cups[2].overall,
    StarMapReadingService.build(now: DateTime(2026, 8, 19), sunSign: ZodiacSignId.leo, discovery: profile).overview.mainMessage,
  ];
}
