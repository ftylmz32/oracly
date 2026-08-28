/// Phase 4 — Yıldızname uses real cross-modal themes; honest empty.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reading_presentation.dart';
import 'package:oracly_new/features/star_map/services/star_map_personalization.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

void main() {
  final discovery = PersonalDiscoveryProfile(
    crossInsights: [
      CrossDiscoveryInsight(
        theme: 'sınırlar',
        sources: const ['tarot', 'coffee'],
        confidence: DiscoveryThemeStrength.recurring,
        lastObserved: DateTime(2026, 8, 13),
        sourceCount: 2,
        discoveryCount: 2,
        recencyWeight: 1,
      ),
      CrossDiscoveryInsight(
        theme: 'yön değiştirme',
        sources: const ['tarot', 'dream'],
        confidence: DiscoveryThemeStrength.recurring,
        lastObserved: DateTime(2026, 8, 13),
        sourceCount: 2,
        discoveryCount: 2,
        recencyWeight: 1,
      ),
    ],
  );

  test('no history keeps an honest empty reflection', () {
    final reading = StarMapReadingService.build(now: DateTime(2026, 8, 13));
    expect(reading.innerThemesLine, PersonalThemeCopy.insufficient);
    expect(reading.recurringThemesLine, PersonalThemeCopy.insufficient);
    expect(reading.todayReflection, PersonalThemeCopy.insufficient);
    expect(reading.todayReflection.toLowerCase(), isNot(contains('karmik')));
  });

  test('real themes produce observational reflection, not diagnosis', () {
    final reading = StarMapReadingService.build(
      now: DateTime(2026, 8, 13),
      sunSign: ZodiacSignId.aries,
      discovery: discovery,
    );
    expect(reading.sunLabel, 'Koç');
    expect(reading.recurringThemesLine, contains('yeniden karşına çıkıyor'));
    expect(reading.todayReflection, contains('sınırlar'));
    expect(reading.todayReflection.toLowerCase(), isNot(contains('sen şöylesin')));
    expect(reading.todayReflection.toLowerCase(), isNot(contains('natal')));
  });

  test('inner theme uses discovery only, never catalogue karmic', () {
    final empty = StarMapReadingService.build(now: DateTime(2026, 8, 13));
    expect(
      StarMapReadingPresentation.innerBody(empty),
      isNot(PersonalThemeCopy.insufficient),
    );
    expect(
      StarMapReadingPresentation.innerBody(empty).toLowerCase(),
      contains('çeride'),
    );
    expect(
      StarMapReadingPresentation.innerBody(empty).toLowerCase(),
      isNot(contains('tempo')),
    );
    expect(
      StarMapReadingPresentation.journeyBody(empty).toLowerCase(),
      contains('son dönem'),
    );
    expect(
      StarMapReadingPresentation.thresholdBody(empty).toLowerCase(),
      contains('eşik'),
    );
    expect(
      StarMapReadingPresentation.innerBody(empty),
      isNot(contains(empty.karmic.theme)),
    );

    final filled = StarMapReadingService.build(
      now: DateTime(2026, 8, 13),
      sunSign: ZodiacSignId.aries,
      discovery: discovery,
    );
    expect(StarMapReadingPresentation.innerBody(filled), contains('sınırlar'));
    expect(
      StarMapReadingPresentation.journeyBody(filled),
      contains('yeniden karşına çıkıyor'),
    );
    expect(
      StarMapReadingPresentation.innerBody(filled).toLowerCase(),
      isNot(contains('karmik')),
    );
  });

  test('inner theme sections stay honest and never revive karmic natal', () {
    final reading = StarMapReadingService.build(
      now: DateTime(2026, 8, 13),
      sunSign: ZodiacSignId.leo,
      discovery: discovery,
    );
    final sections = StarMapPersonalization.innerThemeSections(reading);
    final titles = sections.map((s) => s.title).toList();
    expect(titles, contains(StarMapPolishCopy.todayReflectionTitle));
    expect(titles, contains(StarMapPolishCopy.karmicResultTitle));
    expect(titles, contains(StarMapPolishCopy.journeyTitle));
    expect(titles, contains(StarMapPolishCopy.karmicAsk));
    expect(titles, contains(StarMapPolishCopy.leftQuestionTitle));
    expect(titles, isNot(contains('KARMİK ANALİZ')));
    expect(titles, isNot(contains(StarMapPolishCopy.karmicTheme)));
    expect(titles, isNot(contains(StarMapPolishCopy.sunSignTitle)));
  });

  test('first archive entry omits invented chapter depth', () {
    final reading = StarMapReadingService.build(
      now: DateTime(2026, 8, 13),
      sunSign: ZodiacSignId.leo,
    );
    final sections = StarMapPersonalization.innerThemeSections(reading);
    final titles = sections.map((s) => s.title).toList();
    expect(titles, contains(StarMapPolishCopy.todayReflectionTitle));
    expect(titles, contains(StarMapPolishCopy.journeyTitle));
    expect(titles, contains(StarMapPolishCopy.leftQuestionTitle));
    expect(titles, isNot(contains(StarMapPolishCopy.karmicResultTitle)));
    expect(titles, isNot(contains(StarMapPolishCopy.karmicAsk)));
    expect(
      sections.map((s) => s.body),
      contains(StarMapPolishCopy.journeyEmpty),
    );
  });

  test('daily reflection changes with the calendar day', () {
    final a = StarMapReadingService.build(
      now: DateTime(2026, 8, 13),
      discovery: discovery,
    );
    final b = StarMapReadingService.build(
      now: DateTime(2026, 8, 14),
      discovery: discovery,
    );
    expect(a.todayReflection, isNot(equals(b.todayReflection)));
  });

  test('archive voice is not daily astrology', () {
    final reading = StarMapReadingService.build(
      now: DateTime(2026, 8, 13),
      sunSign: ZodiacSignId.aries,
      discovery: discovery,
    );
    for (final text in [
      reading.overview.mainMessage,
      reading.skyMessage.today,
      reading.todayReflection,
      StarMapReadingPresentation.innerBody(reading),
      StarMapReadingPresentation.journeyBody(reading),
      StarMapReadingPresentation.thresholdBody(reading),
      StarMapReadingPresentation.questionBody(reading),
    ]) {
      expect(text, isNot(contains('Bugün senin için asıl mesele')));
      expect(text.toLowerCase(), isNot(contains('yıldızların mesajı')));
      expect(text.toLowerCase(), isNot(contains('evren sana')));
      expect(text.toLowerCase(), isNot(contains('gezegen')));
      expect(text.toLowerCase(), isNot(contains('natal')));
      expect(text.toLowerCase(), isNot(contains('yansıma')));
      expect(text.toLowerCase(), isNot(contains('kaderin')));
      expect(text.toLowerCase(), isNot(contains('olması gerektiği gibi')));
      expect(HumanReader.looksGeneric(text), isFalse);
    }
    expect(reading.overview.mainMessage.contains('?'), isFalse);
    expect(reading.overview.mainMessage, contains('Koç'));
  });
}
