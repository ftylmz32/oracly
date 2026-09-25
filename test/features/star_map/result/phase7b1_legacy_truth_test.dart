/// Phase 7B.1 — legacy scope disclosure must never positively name evidence
/// the legacy runtime cannot prove.
///
/// Verified production facts this file locks in:
/// * `StarMapReadingService.build(sunSign: null)` yields a valid, user-visible
///   reading with NO Sun-sign evidence (`isPersonalized == false`).
/// * `StarMapReferenceRoutes` accepts a null `BirthProfile`.
/// * `StarMapLegacyResultCapture` never stores `sunSignId` or any birth data.
///
/// So legacy chrome must stay generic and fail closed: false understatement is
/// preferable to fabricated evidence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_integrity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_source.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_artifact_reopen_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_scope_note.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_chrome.dart';
import 'package:oracly_new/features/star_map/result/yildizname_scope_resolver.dart';
import 'package:oracly_new/features/star_map/services/star_map_personalization.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

import '../../../features/birth_chart/evidence/test_birth_owner.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

const _locales = ['tr', 'en', 'ru'];

/// Inputs the legacy runtime cannot always prove. A disclosure that names any
/// of them positively is a fabricated-evidence claim.
const _evidenceClaims = <String, List<String>>{
  'tr': [
    'doğum tarih',
    'doğum saat',
    'doğum yer',
    'doğum bilgi',
    'güneş burc',
    'burç',
  ],
  'en': [
    'birth date',
    'birth-date',
    'birthdate',
    'birth time',
    'birth place',
    'birthplace',
    'birth detail',
    'birth information',
    'sun sign',
    'sun-sign',
    'zodiac',
  ],
  'ru': [
    'дата рождения',
    'даты рождения',
    'дату рождения',
    'время рождения',
    'времени рождения',
    'место рождения',
    'места рождения',
    'данных о рождении',
    'солнечн',
    'знак',
  ],
};

/// Natal-precision vocabulary that must never be asserted for legacy.
const _precisionClaims = <String, List<String>>{
  'tr': ['yükselen', 'evler', 'derece', 'hesaplanan', 'efemeris'],
  'en': ['ascendant', 'houses', 'degree', 'calculated', 'ephemeris', 'rising'],
  'ru': ['асцендент', 'дома', 'градус', 'рассчитанн', 'эфемерид'],
};

/// A legacy disclosure must explicitly say it is NOT a precise calculation.
const _negation = <String, String>{
  'tr': 'değildir',
  'en': 'not a precise',
  'ru': 'не точный',
};

void _expectEvidenceSafe(String text, String locale) {
  final body = text.toLowerCase();
  for (final claim in _evidenceClaims[locale]!) {
    expect(
      body.contains(claim),
      isFalse,
      reason: '[$locale] legacy disclosure claims "$claim": $text',
    );
  }
  for (final claim in _precisionClaims[locale]!) {
    expect(
      body.contains(claim),
      isFalse,
      reason: '[$locale] legacy disclosure implies "$claim": $text',
    );
  }
  expect(
    body.contains(_negation[locale]!),
    isTrue,
    reason: '[$locale] must say it is not a precise calculation: $text',
  );
  expect(text.startsWith('star.result'), isFalse, reason: 'raw key leak');
}

// -- live legacy fixtures: built exactly as StarMapReferenceRoutes builds them --

StarMapReading _reading({ZodiacSignId? sun}) =>
    StarMapReadingService.build(now: DateTime(2026, 1, 10), sunSign: sun);

List<StarMapResultSection> _skySections(StarMapReading r) => [
  StarMapResultSection(
    title: StarMapPolishCopy.skyHeadline,
    body: r.skyMessage.today,
  ),
  StarMapResultSection(
    title: StarMapPolishCopy.skyMeaning,
    body: r.skyMessage.interpretation,
  ),
  StarMapResultSection(
    title: StarMapPolishCopy.skyAdvice,
    body: r.skyMessage.advice,
  ),
];

YildiznameResultPresentation _live(
  String kind,
  StarMapReading reading, {
  String lang = 'tr',
}) {
  switch (kind) {
    case 'sky':
      return YildiznameResultPresentation.legacyLive(
        title: StarMapPolishCopy.skyMessageTitle,
        sections: _skySections(reading),
        chromeLanguage: lang,
      );
    case 'karmic':
      return YildiznameResultPresentation.legacyLive(
        title: StarMapPolishCopy.karmicResultTitle,
        sections: StarMapPersonalization.innerThemeSections(reading),
        chromeLanguage: lang,
      );
    case 'planets':
      return YildiznameResultPresentation.legacyLive(
        title: StarMapPolishCopy.planetsTitle,
        sections: [
          StarMapResultSection(
            title: StarMapPolishCopy.symbolicDisclaimer,
            body: StarMapPolishCopy.planetsCatalogueNote,
          ),
        ],
        planets: reading.planets,
        chromeLanguage: lang,
      );
  }
  throw ArgumentError(kind);
}

YildiznameArtifact _legacyArtifact({String? sunSignId}) =>
    YildiznameArtifactFactory.createLegacy(
      ownerId: 'o1',
      id: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      title: 'Gökyüzü Mesajı',
      sections: const [
        StarMapResultSection(title: 'Gökyüzü', body: 'Bugün sakin bir nefes.'),
        StarMapResultSection(title: 'Anlam', body: 'İç sesini dinle.'),
      ],
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: const [
        StarMapPlanetInfluence(
          nameTr: 'Güneş',
          influence: 'odak',
          explanation: 'Sembolik katalog.',
          polarity: StarMapPolarity.balanced,
        ),
      ],
      sunSignId: sunSignId,
      dayKey: '2026-01-10',
      createdAtUtc: DateTime.utc(2026, 1, 10),
    );

/// An old-compatible shape: no sectionKind, planets, sunSignId, dayKey or
/// locale — only what the very first legacy capture could have stored.
YildiznameArtifact _oldLegacyArtifact(Map<String, dynamic> payload) =>
    YildiznameArtifact(
      id: 'yid_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ownerId: 'o1',
      createdAtUtc: DateTime.utc(2025, 6, 1),
      source: YildiznameArtifactSource.legacyLocal,
      contentHash: 'old',
      semanticDedupeKey: 'old',
      payload: payload,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  tearDown(() => OraclyL10n.bind('tr'));

  group('production facts behind the defect', () {
    test('a valid legacy reading can carry NO Sun-sign evidence', () {
      final r = _reading();
      expect(r.isPersonalized, isFalse);
      expect(r.sunLabel, isNull);
      expect(r.skyMessage.today.trim(), isNotEmpty);
      expect(r.planets, isNotEmpty);
    });

    test('a Sun sign, when known, personalizes the reading', () {
      final r = _reading(sun: ZodiacSignId.leo);
      expect(r.isPersonalized, isTrue);
      expect(r.sunLabel, isNotNull);
    });
  });

  group('A/D/E — live legacy without profile or Sun sign', () {
    final noSun = _reading();
    for (final kind in const ['sky', 'karmic']) {
      for (final locale in _locales) {
        test('$kind [$locale] names no birth / Sun-sign input', () {
          final p = _live(kind, noSun, lang: locale);
          _expectEvidenceSafe(p.scopeDisclosure!.body, locale);
        });
      }
    }

    test('presentation is typed live legacy with the lightest scope', () {
      final p = _live('sky', noSun);
      expect(p.source, YildiznameResultSource.legacyLive);
      expect(p.scope, YildiznameResultScope.legacy);
      expect(p.scopeDisclosure!.evidence, YildiznameResolvedScope.legacy);
    });
  });

  group('B — live legacy with a Sun sign stays truthful', () {
    final withSun = _reading(sun: ZodiacSignId.leo);
    for (final locale in _locales) {
      test(
        '[$locale] still generic — the presentation cannot prove inputs',
        () {
          for (final kind in const ['sky', 'karmic']) {
            final p = _live(kind, withSun, lang: locale);
            _expectEvidenceSafe(p.scopeDisclosure!.body, locale);
          }
        },
      );
    }
  });

  group('C — planet catalogue without profile', () {
    final noSun = _reading();
    for (final locale in _locales) {
      test('[$locale] is not described as derived from a natal chart', () {
        final p = _live('planets', noSun, lang: locale);
        expect(p.planets, isNotEmpty);
        _expectEvidenceSafe(p.scopeDisclosure!.body, locale);
      });
    }

    testWidgets('renders safely with the note and no birth evidence', (
      tester,
    ) async {
      final storage = await yildiznameVisualOpenStorage();
      await yildiznameVisualPumpSettled(
        tester,
        viewport: yildiznameVisualCanonicalViewport,
        storage: storage,
        child: StarMapReferenceResultScreen(
          presentation: _live('planets', noSun),
        ),
      );
      expect(tester.takeException(), isNull);
      final note = tester.widget<StarMapScopeNote>(
        find.byType(StarMapScopeNote),
      );
      _expectEvidenceSafe(note.disclosure.body, 'tr');
    });
  });

  group('F — sealed legacy artifact with sunSignId == null', () {
    test('opens with generic disclosure; stored data untouched', () {
      final artifact = _legacyArtifact();
      expect(artifact.payload.containsKey('sunSignId'), isFalse);
      final hash = artifact.contentHash;
      final payloadBefore = '${artifact.payload}';

      for (final locale in _locales) {
        final p = YildiznameArtifactPresentation.of(
          artifact,
          chromeLocale: locale,
        );
        expect(p.source, YildiznameResultSource.legacyArtifact);
        expect(p.scope, YildiznameResultScope.legacy);
        _expectEvidenceSafe(p.scopeDisclosure!.body, locale);
        // J — stored prose + planets exactly as sealed.
        expect(p.title, 'Gökyüzü Mesajı');
        expect(p.sections.map((s) => s.title), ['Gökyüzü', 'Anlam']);
        expect(p.sections.map((s) => s.body), [
          'Bugün sakin bir nefes.',
          'İç sesini dinle.',
        ]);
        expect(p.planets.single.nameTr, 'Güneş');
        expect(p.planets.single.explanation, 'Sembolik katalog.');
      }
      // K — nothing mutated, integrity still verifies.
      YildiznameArtifactIntegrity.verify(artifact);
      expect(artifact.contentHash, hash);
      expect('${artifact.payload}', payloadBefore);
    });
  });

  group('G — sealed legacy artifact with a stored sunSignId', () {
    test('generic disclosure; still no birth-date or precision claim', () {
      final withSun = _legacyArtifact(sunSignId: 'leo');
      final without = _legacyArtifact();
      expect(withSun.payload['sunSignId'], 'leo');
      for (final locale in _locales) {
        final p = YildiznameArtifactPresentation.of(
          withSun,
          chromeLocale: locale,
        );
        _expectEvidenceSafe(p.scopeDisclosure!.body, locale);
        // The conservative copy is identical either way — a stored id must
        // not silently enrich chrome the live path cannot match.
        expect(
          p.scopeDisclosure,
          YildiznameArtifactPresentation.of(
            without,
            chromeLocale: locale,
          ).scopeDisclosure,
        );
      }
      YildiznameArtifactIntegrity.verify(withSun);
    });
  });

  group('H — old legacy artifact missing optional fields', () {
    test('reopens with conservative disclosure and never throws', () {
      final shapes = <Map<String, dynamic>>[
        {
          'title': 'Eski Başlık',
          'sections': [
            {'title': 'Bölüm', 'body': 'Eski metin.'},
          ],
        },
        {'sections': 'not-a-list'},
        {'title': 7, 'planets': 'nope'},
        <String, dynamic>{},
      ];
      for (final payload in shapes) {
        for (final locale in _locales) {
          final p = YildiznameArtifactPresentation.of(
            _oldLegacyArtifact(payload),
            chromeLocale: locale,
          );
          expect(p.scope, YildiznameResultScope.legacy);
          expect(p.source, YildiznameResultSource.legacyArtifact);
          _expectEvidenceSafe(p.scopeDisclosure!.body, locale);
        }
      }
      final stored = YildiznameArtifactPresentation.of(
        _oldLegacyArtifact(shapes.first),
        chromeLocale: 'tr',
      );
      expect(stored.title, 'Eski Başlık');
      expect(stored.sections.single.body, 'Eski metin.');
    });
  });

  group('I — a current profile never enriches an old artifact', () {
    test('projection is pure — no profile parameter exists', () {
      final a = _oldLegacyArtifact({
        'title': 'Eski Başlık',
        'sections': [
          {'title': 'Bölüm', 'body': 'Eski metin.'},
        ],
      });
      expect(
        YildiznameArtifactPresentation.of(a, chromeLocale: 'tr'),
        YildiznameArtifactPresentation.of(a, chromeLocale: 'tr'),
      );
    });

    testWidgets('reopen note is identical with and without a stored profile', (
      tester,
    ) async {
      final artifact = _oldLegacyArtifact({
        'title': 'Eski Başlık',
        'sections': [
          {'title': 'Bölüm', 'body': 'Eski metin.'},
        ],
      });

      Future<String> reopenNote({required bool withProfile}) async {
        final storage = await yildiznameVisualOpenStorage();
        if (withProfile) {
          final chart = const NatalChartCalculator().calculate(
            yildiznameVisualBirthProfile(),
          );
          await testBirthChartRepo(
            storage,
          ).save(BirthChartRecordMapper.toRecord(chart));
        }
        await yildiznameVisualPumpSettled(
          tester,
          viewport: yildiznameVisualCanonicalViewport,
          storage: storage,
          child: StarMapArtifactReopenScreen(artifact: artifact),
        );
        expect(tester.takeException(), isNull);
        return tester
            .widget<StarMapScopeNote>(find.byType(StarMapScopeNote))
            .disclosure
            .body;
      }

      final without = await reopenNote(withProfile: false);
      final withProfile = await reopenNote(withProfile: true);
      expect(withProfile, without);
      _expectEvidenceSafe(withProfile, 'tr');
    });
  });

  group('O — legacy copy is safe and localized in every locale', () {
    test('no raw key, no cross-language leakage', () {
      final cyrillic = RegExp(r'[А-Яа-яЁё]');
      for (final locale in _locales) {
        final body = YildiznameResultChrome.scopeBody(
          YildiznameResolvedScope.legacy,
          locale,
        );
        expect(body.startsWith('star.result'), isFalse);
        expect(cyrillic.hasMatch(body), locale == 'ru', reason: locale);
        _expectEvidenceSafe(body, locale);
      }
    });

    test('copy is pinned — changing it must be deliberate', () {
      expect(
        YildiznameResultChrome.scopeBody(YildiznameResolvedScope.legacy, 'tr'),
        _legacyTr,
      );
      expect(
        YildiznameResultChrome.scopeBody(YildiznameResolvedScope.legacy, 'en'),
        _legacyEn,
      );
      expect(
        YildiznameResultChrome.scopeBody(YildiznameResolvedScope.legacy, 'ru'),
        _legacyRu,
      );
    });
  });

  group('L/M/N — Narrative 7B copy is unchanged', () {
    const reduced = YildiznameResolvedScope(
      scope: YildiznameResultScope.reduced,
    );
    const full = YildiznameResolvedScope(
      scope: YildiznameResultScope.full,
      hasAscendant: true,
      hasMidheaven: true,
      hasHouses: true,
      hasAspects: true,
    );
    const partial = YildiznameResolvedScope(scope: YildiznameResultScope.full);

    test('kicker', () {
      expect(YildiznameResultChrome.scopeKicker('tr'), 'Bu yorumun dayanağı');
      expect(
        YildiznameResultChrome.scopeKicker('en'),
        'What this reading rests on',
      );
      expect(
        YildiznameResultChrome.scopeKicker('ru'),
        'На чём основано это толкование',
      );
    });

    test('REDUCED', () {
      expect(
        YildiznameResultChrome.scopeBody(reduced, 'tr'),
        'Elde bulunan doğum bilgilerine göre kişiselleştirilmiş bir yorum. Doğum saati kesin olmadığı için Yükselen ve evler gibi saate bağlı katmanlar dahil edilmedi.',
      );
      expect(
        YildiznameResultChrome.scopeBody(reduced, 'en'),
        'A personalized interpretation based on the birth details available. Because the birth time is not certain, time-dependent layers such as the Ascendant and houses are not included.',
      );
      expect(
        YildiznameResultChrome.scopeBody(reduced, 'ru'),
        'Персональное толкование на основе имеющихся данных о рождении. Поскольку время рождения неточно, слои, зависящие от времени, — такие как Асцендент и дома, — не включены.',
      );
    });

    test('FULL (every layer) and FULL (partial / omitted houses or ascendant)', () {
      expect(
        YildiznameResultChrome.scopeBody(full, 'tr'),
        'Hesaplanan doğum bilgilerine dayanan bir doğum haritası yorumu.',
      );
      expect(
        YildiznameResultChrome.scopeBody(full, 'en'),
        'A natal interpretation based on the birth details that were calculated.',
      );
      expect(
        YildiznameResultChrome.scopeBody(full, 'ru'),
        'Натальное толкование на основе рассчитанных данных о рождении.',
      );
      expect(
        YildiznameResultChrome.scopeBody(partial, 'tr'),
        'Hesaplanan doğum bilgilerine dayanan bir doğum haritası yorumu. Yalnızca gerçekten hesaplanabilen katmanlar kullanıldı.',
      );
      expect(
        YildiznameResultChrome.scopeBody(partial, 'en'),
        'A natal interpretation based on the birth details that were calculated. Only the layers that could actually be calculated were used.',
      );
      expect(
        YildiznameResultChrome.scopeBody(partial, 'ru'),
        'Натальное толкование на основе рассчитанных данных о рождении. Использованы только те слои, которые действительно удалось рассчитать.',
      );
    });
  });
}

// Pinned legacy copy — generic, fail-closed, names no evidence input.
const _legacyTr =
    'Bu okuma için mevcut sembolik Yıldızname bağlamına dayanan bir yorum. Kesin bir doğum haritası hesabı değildir.';
const _legacyEn =
    'A symbolic Yıldızname interpretation based only on the context available to this reading. It is not a precise natal-chart calculation.';
const _legacyRu =
    'Символическое толкование Йылдызнаме, основанное только на контексте, доступном этому чтению. Это не точный расчёт натальной карты.';
