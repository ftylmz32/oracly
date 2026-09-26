/// Phase 7C — the fact snapshot inside the ONE canonical result screen:
/// position, treatment, localization, accessibility, responsiveness, purity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_integrity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_artifact_reopen_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_planet_card.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_scope_note.dart';
import 'package:oracly_new/features/star_map/result/yildizname_fact_snapshot.dart';

import '../../../features/birth_chart/evidence/test_birth_owner.dart';
import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_golden_harness.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

const _full = YildiznameNarrativeScope.full;

Future<void> _pumpReopen(
  WidgetTester tester,
  YildiznameArtifact artifact, {
  Size viewport = yildiznameVisualCanonicalViewport,
  double textScale = 1.0,
}) async {
  final storage = await yildiznameVisualOpenStorage();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: viewport,
    textScale: textScale,
    storage: storage,
    child: StarMapArtifactReopenScreen(artifact: artifact),
  );
}

YildiznameArtifact _fullArtifact({
  bool rich = true,
  bool ascendant = true,
  bool midheaven = true,
  bool houses = true,
  bool aspects = true,
  String languageCode = 'tr',
}) => yildiznameFixtureNarrativeArtifact(
  id: 'yid_dddddddddddddddddddddddddddddddd',
  scope: _full,
  rich: rich,
  ascendant: ascendant,
  midheaven: midheaven,
  houses: houses,
  aspects: aspects,
  languageCode: languageCode,
);

List<String> _plateTexts(WidgetTester tester) => [
  for (final w in tester.widgetList<RichText>(
    find.descendant(
      of: find.byType(StarMapFactSnapshotPlate),
      matching: find.byType(RichText),
    ),
  ))
    w.text.toPlainText(),
];

const _rawWire = [
  'factRef',
  'placement.',
  'angle.',
  'house.',
  'aspect.',
  'intervalStable',
  'exact',
  'ambiguous',
  'unavailable',
  'unsupported',
  'wholeSign',
  'omittedLayers',
  'fullNatalEphemeris',
  'reducedNatal',
  'calculationVersion',
  'serializerVersion',
  'evidenceFingerprint',
  'semanticFingerprint',
  'yid_',
  'star.fact.',
  'planet.',
  'zodiac.',
  'birth.element',
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
  'ascendant',
  'midheaven',
  'conjunction',
  'sextile',
  'square',
  'trine',
  'opposition',
  'leo',
  'taurus',
  'scorpio',
  'virgo',
  'libra',
  'aries',
  'sagittarius',
  'capricorn',
  'aquarius',
  'pisces',
  'cardinal',
  'fixed',
  'mutable',
];

Future<void> _openDeeper(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('starFactMoreToggle')));
  await tester.tap(find.byKey(const ValueKey('starFactMoreToggle')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  tearDown(() => OraclyL10n.bind('tr'));

  group('position — app bar → scope note → facts → summary → chapters', () {
    testWidgets('FULL: the plate sits between the scope note and the summary', (
      tester,
    ) async {
      await _pumpReopen(tester, _fullArtifact());
      final note = tester.getTopLeft(find.byType(StarMapScopeNote)).dy;
      final plate = tester.getTopLeft(find.byType(StarMapFactSnapshotPlate)).dy;
      final summary = tester.getTopLeft(find.text('Özet')).dy;
      final chapter = tester.getTopLeft(find.text('Kimlik')).dy;
      final appBar = tester.getTopLeft(find.text('YILDIZNAME')).dy;
      expect(appBar, lessThan(note));
      expect(note, lessThan(plate));
      expect(plate, lessThan(summary));
      expect(summary, lessThan(chapter));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the screen is still the single canonical owner', (
      tester,
    ) async {
      await _pumpReopen(tester, _fullArtifact());
      expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
      expect(find.byType(StarMapFactSnapshotPlate), findsOneWidget);
    });
  });

  group('legacy: no fact layer', () {
    testWidgets('legacy artifact reopen has no plate and keeps its cards', (
      tester,
    ) async {
      await yildiznameGoldenPumpLegacyArtifactReopen(tester);
      expect(find.byType(StarMapFactSnapshotPlate), findsNothing);
      expect(find.byType(StarMapScopeNote), findsOneWidget);
      expect(find.byType(StarMapReferencePlanetCard), findsWidgets);
      expect(find.text('Doğum göğün'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('legacy live result has no plate', (tester) async {
      await yildiznameGoldenPumpPresentation(
        tester,
        presentation: YildiznameResultPresentation.legacyLive(
          title: 'Gökyüzü Mesajı',
          sections: yildiznameVisualLegacySections(),
          planets: yildiznameVisualLegacyPlanets(),
        ),
      );
      expect(find.byType(StarMapFactSnapshotPlate), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unscoped compatibility path has no plate', (tester) async {
      await yildiznameGoldenPumpResult(
        tester,
        title: 'Gökyüzü Mesajı',
        sections: yildiznameVisualLegacySections(),
      );
      expect(find.byType(StarMapFactSnapshotPlate), findsNothing);
    });
  });

  group('REDUCED: complete within scope, never broken', () {
    testWidgets('signs only, no degree / house / deeper toggle', (
      tester,
    ) async {
      await _pumpReopen(tester, yildiznameFixtureNarrativeArtifact());
      expect(find.byType(StarMapFactSnapshotPlate), findsOneWidget);
      final texts = _plateTexts(tester).join(' | ');
      expect(texts, contains('Doğum göğün'));
      expect(texts, contains('Güneş'));
      expect(texts, contains('Aslan'));
      expect(texts, contains('Merkür'));
      expect(texts, contains('Başak'));
      expect(texts.contains('°'), isFalse);
      expect(texts.contains(' ev'), isFalse);
      expect(find.byKey(const ValueKey('starFactMoreToggle')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('FULL: primary · secondary · folded deeper layer', () {
    testWidgets('primary facts are visible, precise and localized', (
      tester,
    ) async {
      await _pumpReopen(tester, _fullArtifact());
      final texts = _plateTexts(tester).join(' | ');
      for (final want in const [
        'Güneş',
        'Aslan',
        '22° · 10. ev',
        'Ay',
        'Boğa',
        '3° · 7. ev',
        'Yükselen',
        'Akrep',
        '11°',
        'Gökyüzü Ortası',
        '19°',
        'Merkür',
        'Başak',
        'Venüs',
        'Terazi',
        'Mars',
        'Koç',
      ]) {
        expect(texts, contains(want), reason: want);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the deeper layer is folded by default and opens on tap', (
      tester,
    ) async {
      await _pumpReopen(tester, _fullArtifact());
      expect(find.text('Gökyüzünün ayrıntıları'), findsOneWidget);
      // Folded: outer planets, aspects and balances are absent.
      for (final absent in const [
        'Dış gezegenler',
        'Öne çıkan açılar',
        'Baskın element',
        'Jüpiter',
      ]) {
        expect(_plateTexts(tester).join(' | ').contains(absent), isFalse);
      }
      await _openDeeper(tester);
      final opened = _plateTexts(tester).join(' | ');
      for (final want in const [
        'Dış gezegenler',
        'Jüpiter',
        'Satürn',
        'Öne çıkan açılar',
        'Merkür · Venüs',
        'Kavuşum',
        'Baskın element',
        'Ateş',
        'Baskın nitelik',
        'Sabit',
      ]) {
        expect(opened, contains(want), reason: want);
      }
      // Fully closed again.
      await _openDeeper(tester);
      expect(_plateTexts(tester).join(' | ').contains('Jüpiter'), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a real 0° outer planet renders as 0°', (tester) async {
      await _pumpReopen(tester, _fullArtifact());
      await _openDeeper(tester);
      // Saturn is stored at exactly 0.0 in the rich fixture.
      expect(
        _plateTexts(
          tester,
        ).any((t) => t.contains('Satürn') && t.contains('0°')),
        isTrue,
      );
    });

    testWidgets(
      'the toggle is a ≥44px full-width target with button semantics',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpReopen(tester, _fullArtifact());
        final size = tester.getSize(
          find.byKey(const ValueKey('starFactMoreToggle')),
        );
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThan(200));
        final toggle = find.bySemanticsLabel('Gökyüzünün ayrıntıları');
        expect(
          tester.getSemantics(toggle),
          isSemantics(
            label: 'Gökyüzünün ayrıntıları',
            isButton: true,
            hasTapAction: true,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );
        await _openDeeper(tester);
        expect(
          tester.getSemantics(toggle),
          isSemantics(isButton: true, hasExpandedState: true, isExpanded: true),
        );
        handle.dispose();
      },
    );
  });

  group('partial FULL: absence means omission', () {
    testWidgets('no Ascendant / houses / aspects → none rendered', (
      tester,
    ) async {
      await _pumpReopen(
        tester,
        _fullArtifact(ascendant: false, houses: false, aspects: false),
      );
      final texts = _plateTexts(tester).join(' | ');
      expect(texts.contains('Yükselen'), isFalse);
      expect(texts.contains(' ev'), isFalse);
      expect(texts, contains('Güneş'));
      expect(texts, contains('22°'));
      await _openDeeper(tester);
      final opened = _plateTexts(tester).join(' | ');
      expect(opened.contains('Öne çıkan açılar'), isFalse);
      for (final t in const ['—', 'Bilinmiyor', 'null']) {
        expect(opened.contains(t), isFalse, reason: t);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a FULL artifact with no usable request shows no plate', (
      tester,
    ) async {
      final base = _fullArtifact();
      final payload = Map<String, dynamic>.from(base.payload)
        ..remove('request');
      await _pumpReopen(
        tester,
        yildiznameFixtureRawNarrativeArtifact(
          payload: payload,
          scope: 'full',
          fidelity: 'fullNatalEphemeris',
        ),
      );
      expect(find.byType(StarMapFactSnapshotPlate), findsNothing);
      expect(find.text('Özet'), findsOneWidget, reason: 'prose still opens');
      expect(find.byType(StarMapScopeNote), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('T — the current profile never enriches an old artifact', () {
    testWidgets('reduced reopen is identical with and without a rich profile', (
      tester,
    ) async {
      Future<List<String>> reopen({required bool withProfile}) async {
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
          child: StarMapArtifactReopenScreen(
            artifact: yildiznameFixtureNarrativeArtifact(),
          ),
        );
        expect(tester.takeException(), isNull);
        return _plateTexts(tester);
      }

      final without = await reopen(withProfile: false);
      final withProfile = await reopen(withProfile: true);
      expect(withProfile, without);
      expect(withProfile.join(' | ').contains('°'), isFalse);
      expect(withProfile.join(' | ').contains('Yükselen'), isFalse);
    });
  });

  group('live / artifact parity through the same screen', () {
    testWidgets('narrativeLive renders the same plate as the artifact', (
      tester,
    ) async {
      final artifact = _fullArtifact();
      final fromArtifact = YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'tr',
      );
      final live = YildiznameArtifactPresentation.narrativeLive(
        request: yildiznameFixtureRequest(scope: _full, rich: true),
        result: yildiznameFixtureResult(scope: _full, kinds: const []),
        chromeLocale: 'tr',
      );
      expect(live.factSnapshot, fromArtifact.factSnapshot);

      await yildiznameGoldenPumpPresentation(
        tester,
        presentation: fromArtifact,
      );
      final a = _plateTexts(tester);
      await yildiznameGoldenPumpPresentation(tester, presentation: live);
      final b = _plateTexts(tester);
      expect(b, a);
      expect(a, isNotEmpty);
    });
  });

  group('presentation contract', () {
    test('withoutFactSnapshot restores the 7B shape', () {
      final p = YildiznameArtifactPresentation.of(
        _fullArtifact(),
        chromeLocale: 'tr',
      );
      expect(p.factSnapshot.isNotEmpty, isTrue);
      final bare = p.withoutFactSnapshot();
      expect(bare.factSnapshot, YildiznameFactSnapshot.empty);
      expect(bare.sections, p.sections);
      expect(bare.scopeDisclosure, p.scopeDisclosure);
      expect(bare == p, isFalse, reason: 'facts are part of value equality');
    });

    test('equal projections are value-equal with equal hashes', () {
      final a = YildiznameArtifactPresentation.of(
        _fullArtifact(),
        chromeLocale: 'tr',
      );
      final b = YildiznameArtifactPresentation.of(
        _fullArtifact(),
        chromeLocale: 'tr',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('chrome language changes labels, never the facts themselves', () {
      final tr = YildiznameArtifactPresentation.of(
        _fullArtifact(),
        chromeLocale: 'tr',
      ).factSnapshot;
      final en = YildiznameArtifactPresentation.of(
        _fullArtifact(),
        chromeLocale: 'en',
      ).factSnapshot;
      expect(tr.facts.map((f) => f.subject), en.facts.map((f) => f.subject));
      expect(tr.aspects.length, en.aspects.length);
      expect(tr.title, isNot(en.title));
    });
  });

  group('immutability through the screen', () {
    testWidgets('rendering leaves payload, hash and integrity untouched', (
      tester,
    ) async {
      final artifact = _fullArtifact();
      Object? copy(Object? v) {
        if (v is Map) return {for (final e in v.entries) e.key: copy(e.value)};
        if (v is List) return [for (final e in v) copy(e)];
        return v;
      }

      final before = copy(artifact.payload);
      final hash = artifact.contentHash;
      await _pumpReopen(tester, artifact);
      await _openDeeper(tester);
      expect(artifact.payload, before);
      expect(artifact.contentHash, hash);
      YildiznameArtifactIntegrity.verify(artifact);
    });
  });

  group('localization + identifier firewall (rendered)', () {
    for (final lang in const ['tr', 'en', 'ru']) {
      testWidgets('$lang: full plate, folded and opened, leaks nothing', (
        tester,
      ) async {
        await yildiznameVisualBindLocale(lang);
        final presentation = YildiznameArtifactPresentation.of(
          _fullArtifact(languageCode: lang),
          chromeLocale: lang,
        );
        await yildiznameGoldenPumpPresentation(
          tester,
          presentation: presentation,
        );
        await _openDeeper(tester);
        final texts = _plateTexts(tester);
        expect(texts, isNotEmpty);
        for (final t in texts) {
          for (final raw in _rawWire) {
            expect(t.contains(raw), isFalse, reason: '"$t" leaks "$raw"');
          }
        }
        // Visible chrome is in the chosen language.
        final joined = texts.join(' | ');
        final cyrillic = RegExp(r'[А-Яа-яЁё]');
        expect(cyrillic.hasMatch(joined), lang == 'ru');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('responsive + text scale (no overflow, no clipping)', () {
    const viewports = <String, (Size, double)>{
      '320x568': (Size(320, 568), 1.0),
      '390x844': (Size(390, 844), 1.0),
      '412x915': (Size(412, 915), 1.0),
      '360x800@1.3': (Size(360, 800), 1.3),
      '320x568@1.3': (Size(320, 568), 1.3),
    };
    for (final lang in const ['tr', 'en', 'ru']) {
      viewports.forEach((name, spec) {
        testWidgets('$lang $name: plate + deeper layer fit', (tester) async {
          await yildiznameVisualBindLocale(lang);
          final (size, scale) = spec;
          final presentation = YildiznameArtifactPresentation.of(
            _fullArtifact(languageCode: lang),
            chromeLocale: lang,
          );
          await yildiznameGoldenPumpPresentation(
            tester,
            presentation: presentation,
            viewport: size,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          final plate = tester.getRect(find.byType(StarMapFactSnapshotPlate));
          expect(plate.left, greaterThanOrEqualTo(0));
          expect(plate.right, lessThanOrEqualTo(size.width));
          await _openDeeper(tester);
          expect(tester.takeException(), isNull);
          // Every plate text stays inside the plate horizontally.
          final plateRect = tester.getRect(
            find.byType(StarMapFactSnapshotPlate),
          );
          for (final e in tester.elementList(
            find.descendant(
              of: find.byType(StarMapFactSnapshotPlate),
              matching: find.byType(RichText),
            ),
          )) {
            final r = tester.getRect(find.byElementPredicate((x) => x == e));
            expect(r.left, greaterThanOrEqualTo(plateRect.left - 0.5));
            expect(r.right, lessThanOrEqualTo(plateRect.right + 0.5));
          }
        });
      });
    }
  });

  group('accessibility', () {
    testWidgets('every fact has a calm label; reading order = visual order', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpReopen(tester, _fullArtifact());
      final order = [
        YildiznameFactSubject.sun,
        YildiznameFactSubject.moon,
        YildiznameFactSubject.ascendant,
        YildiznameFactSubject.midheaven,
        YildiznameFactSubject.mercury,
        YildiznameFactSubject.venus,
        YildiznameFactSubject.mars,
      ];
      final ys = <double>[];
      final xs = <double>[];
      for (final subject in order) {
        final finder = find.byKey(ValueKey(subject));
        expect(finder, findsOneWidget, reason: '$subject');
        final semantics = tester.getSemantics(finder);
        expect(semantics.label, isNotEmpty);
        expect(
          RegExp(r'[A-Za-z]+\.[A-Za-z]+').hasMatch(semantics.label),
          isFalse,
          reason: 'no raw "a.b" identifier in "${semantics.label}"',
        );
        final at = tester.getTopLeft(finder);
        ys.add(at.dy);
        xs.add(at.dx);
      }
      // Primary tiles read row-major; secondary follows after all primary.
      for (var i = 1; i < 4; i++) {
        final sameRow = (ys[i] - ys[i - 1]).abs() < 1;
        expect(
          ys[i] > ys[i - 1] || (sameRow && xs[i] > xs[i - 1]),
          isTrue,
          reason: 'primary tile $i reads after tile ${i - 1}',
        );
      }
      expect(ys[4], greaterThan(ys[3]));
      expect(
        tester
            .getSemantics(find.byKey(ValueKey(YildiznameFactSubject.sun)))
            .label,
        'Güneş, Aslan, 22° · 10. ev',
      );
      handle.dispose();
    });

    testWidgets('the plate title is a header', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpReopen(tester, _fullArtifact());
      expect(
        tester.getSemantics(find.text('Doğum göğün')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('REDUCED manufactures no button', (tester) async {
      await _pumpReopen(tester, yildiznameFixtureNarrativeArtifact());
      expect(
        find.descendant(
          of: find.byType(StarMapFactSnapshotPlate),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });
  });

  group('no dashboard, no fake chart', () {
    testWidgets('the plate is one compact block, not a grid of cards', (
      tester,
    ) async {
      await _pumpReopen(tester, _fullArtifact());
      expect(find.byType(StarMapFactSnapshotPlate), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets); // atmosphere only
      final plate = tester.getSize(find.byType(StarMapFactSnapshotPlate));
      final screen = tester.getSize(find.byType(StarMapReferenceResultScreen));
      // The summary — not the data — stays the hero: the plate never takes
      // more than half the first screen.
      expect(plate.height, lessThan(screen.height / 2));
    });
  });
}
