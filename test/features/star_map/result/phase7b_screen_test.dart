/// Phase 7B — canonical result screen: localized chrome + scope note.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_artifact_reopen_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_app_bar.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_planet_card.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_footer.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_scope_note.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_golden_harness.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

List<String> _visible(WidgetTester tester) => [
  for (final w in tester.widgetList<RichText>(find.byType(RichText)))
    w.text.toPlainText(),
];

const _rawNames = <String>[
  'summary',
  'reflection',
  'closing',
  'coreIdentity',
  'emotionalWorld',
  'mindAndExpression',
  'relationshipsAndValues',
  'driveAndGrowth',
  'anglesAndHouses',
  'patternsAndTensions',
  'strengthsAndResources',
  'archiveEcho',
  'practicalReflection',
  'core_identity',
  'emotional_world',
  'angles_and_houses',
  'reducedNatal',
  'fullNatalEphemeris',
  'tropicalSunSign',
  'theme.',
  'yth_',
  'factRef',
  'semanticFingerprint',
  'evidenceFingerprint',
  'yid_',
];

void _expectNoRaw(WidgetTester tester) {
  for (final text in _visible(tester)) {
    for (final raw in _rawNames) {
      expect(
        text == raw || text.contains(raw),
        isFalse,
        reason: 'visible text "$text" leaks "$raw"',
      );
    }
  }
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  tearDown(() => OraclyL10n.bind('tr'));

  testWidgets('A — reduced artifact: localized chrome + reduced note', (
    tester,
  ) async {
    await _pumpReopen(tester, yildiznameFixtureNarrativeArtifact());
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    expect(find.text('YILDIZNAME'), findsOneWidget); // app bar product label
    for (final t in const ['Özet', 'Kimlik', 'Üzerine düşün', 'Kapanış']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.byType(StarMapScopeNote), findsOneWidget);
    expect(find.text('Bu yorumun dayanağı'), findsOneWidget);
    expect(find.textContaining('kişiselleştirilmiş'), findsOneWidget);
    expect(find.textContaining('dahil edilmedi'), findsOneWidget);
    _expectNoRaw(tester);
    expect(find.textContaining('°'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('B — full artifact: general full note, no fact cards yet', (
    tester,
  ) async {
    await _pumpReopen(
      tester,
      yildiznameFixtureNarrativeArtifact(
        id: 'yid_dddddddddddddddddddddddddddddddd',
        scope: YildiznameNarrativeScope.full,
      ),
    );
    expect(
      find.text(
        'Hesaplanan doğum bilgilerine dayanan bir doğum haritası yorumu.',
      ),
      findsOneWidget,
    );
    for (final t in const [
      'Özet',
      'Kimlik',
      'Duygusal dünya',
      'Açılar ve evler',
      'Üzerine düşün',
      'Kapanış',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // 7C has not landed: no fact cards, no planet cards, no degrees.
    expect(find.byType(StarMapReferencePlanetCard), findsNothing);
    expect(find.textContaining('°'), findsNothing);
    _expectNoRaw(tester);
    expect(tester.takeException(), isNull);
  });

  for (final variant in const ['houses', 'ascendant']) {
    testWidgets('C/D — FULL without $variant never claims it', (tester) async {
      await _pumpReopen(
        tester,
        yildiznameFixtureNarrativeArtifact(
          scope: YildiznameNarrativeScope.full,
          houses: variant != 'houses',
          ascendant: variant != 'ascendant',
        ),
      );
      expect(
        find.textContaining('Yalnızca gerçekten hesaplanabilen katmanlar'),
        findsOneWidget,
      );
      final note = tester.widget<StarMapScopeNote>(
        find.byType(StarMapScopeNote),
      );
      expect(note.disclosure.body.contains('Yükselen'), isFalse);
      expect(note.disclosure.body.contains('evler'), isFalse);
      _expectNoRaw(tester);
    });
  }

  testWidgets('E — conflicting metadata renders the conservative note', (
    tester,
  ) async {
    final base = yildiznameFixtureNarrativeArtifact(
      scope: YildiznameNarrativeScope.full,
    );
    await _pumpReopen(
      tester,
      yildiznameFixtureRawNarrativeArtifact(
        payload: Map<String, dynamic>.from(base.payload),
        scope: 'full',
        fidelity: 'reducedNatal',
      ),
    );
    expect(find.textContaining('kişiselleştirilmiş'), findsOneWidget);
    expect(find.textContaining('doğum haritası yorumu'), findsNothing);
    _expectNoRaw(tester);
  });

  testWidgets('F — legacy live: symbolic note, nothing natal', (tester) async {
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualCanonicalViewport,
      storage: storage,
      child: StarMapReferenceResultScreen(
        presentation: YildiznameResultPresentation.legacyLive(
          title: 'Gökyüzü Mesajı',
          sections: yildiznameVisualLegacySections(),
          planets: yildiznameVisualLegacyPlanets(),
        ),
      ),
    );
    expect(find.byType(StarMapScopeNote), findsOneWidget);
    expect(find.textContaining('Kesin bir gök haritası'), findsOneWidget);
    expect(find.textContaining('Yükselen'), findsNothing);
    expect(find.byType(StarMapReferencePlanetCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G — legacy artifact reopen: same safe semantics', (
    tester,
  ) async {
    await yildiznameGoldenPumpLegacyArtifactReopen(tester);
    expect(find.byType(StarMapScopeNote), findsOneWidget);
    expect(find.textContaining('sembolik bir yorum'), findsWidgets);
    expect(find.text('Gökyüzü Mesajı'), findsWidgets);
    expect(find.byType(StarMapReferencePlanetCard), findsOneWidget);
    expect(find.textContaining('Yükselen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('I — English chrome, Turkish prose, no crash', (tester) async {
    await yildiznameVisualBindLocale('en');
    await _pumpReopen(tester, yildiznameFixtureNarrativeArtifact());
    for (final t in const ['Summary', 'Identity', 'To reflect on', 'Closing']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('What this reading rests on'), findsOneWidget);
    expect(
      find.textContaining('Güneş Leo konumunda'),
      findsOneWidget,
      reason: 'stored prose keeps its stored language',
    );
    expect(find.text('Özet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('I — Russian chrome, Turkish prose, no crash', (tester) async {
    await yildiznameVisualBindLocale('ru');
    await _pumpReopen(tester, yildiznameFixtureNarrativeArtifact());
    for (final t in const [
      'Кратко',
      'Идентичность',
      'Для размышления',
      'Завершение',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.textContaining('Güneş Leo konumunda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('J — unknown kind: neutral chrome, prose kept, no identifier', (
    tester,
  ) async {
    final base = yildiznameFixtureNarrativeArtifact();
    final payload = Map<String, dynamic>.from(base.payload);
    payload['result'] = {
      ...Map<String, dynamic>.from(payload['result'] as Map),
      'sections': [
        {
          'kind': 'wisdom_of_the_ages',
          'text': 'Gelecekten gelen geçerli metin.',
        },
      ],
    };
    await _pumpReopen(
      tester,
      yildiznameFixtureRawNarrativeArtifact(
        payload: payload,
        scope: 'reduced',
        fidelity: 'reducedNatal',
      ),
    );
    expect(find.text('Fasıl'), findsOneWidget);
    expect(find.text('Gelecekten gelen geçerli metin.'), findsOneWidget);
    expect(find.textContaining('wisdom_of_the_ages'), findsNothing);
    _expectNoRaw(tester);
  });

  testWidgets('layout — note precedes summary; roles keep reading order', (
    tester,
  ) async {
    await _pumpReopen(tester, yildiznameFixtureNarrativeArtifact());
    double y(Finder f) => tester.getTopLeft(f).dy;
    final note = y(find.text('Bu yorumun dayanağı'));
    final summary = y(find.text('Özet'));
    final chapter = y(find.text('Kimlik'));
    final reflection = y(find.text('Üzerine düşün'));
    final closing = y(find.text('Kapanış'));
    expect(note < summary, isTrue, reason: 'disclosure before summary');
    expect(summary < chapter, isTrue);
    expect(chapter < reflection, isTrue);
    expect(reflection < closing, isTrue);
  });

  testWidgets('canonical owner — one screen, one scroll owner, one note', (
    tester,
  ) async {
    await _pumpReopen(
      tester,
      yildiznameFixtureNarrativeArtifact(scope: YildiznameNarrativeScope.full),
    );
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    expect(find.byType(OraclyAdaptiveScrollView), findsOneWidget);
    expect(find.byType(StarMapReferenceAppBar), findsOneWidget);
    expect(find.byType(StarMapResultFooter), findsOneWidget);
    expect(find.byType(StarMapScopeNote), findsOneWidget);
  });

  testWidgets('note is quiet chrome — not interactive, semantics readable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpReopen(tester, yildiznameFixtureNarrativeArtifact());
    final note = find.byType(StarMapScopeNote);
    expect(
      find.descendant(of: note, matching: find.byType(GestureDetector)),
      findsNothing,
    );
    expect(
      find.descendant(of: note, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(find.bySemanticsLabel(RegExp('Bu yorumun dayanağı')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('dahil edilmedi')), findsWidgets);
    handle.dispose();
  });

  for (final size in yildiznameVisualViewports) {
    testWidgets(
      'no overflow @ ${size.width.toInt()}x${size.height.toInt()} (longest note)',
      (tester) async {
        await _pumpReopen(
          tester,
          yildiznameFixtureNarrativeArtifact(
            scope: YildiznameNarrativeScope.full,
            houses: false,
            kinds: YildiznameSectionKind.values,
          ),
          viewport: size,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(StarMapScopeNote), findsOneWidget);
      },
    );
  }

  for (final locale in const ['tr', 'en', 'ru']) {
    testWidgets('a11y textScale 1.3 — note stays readable [$locale]', (
      tester,
    ) async {
      await yildiznameVisualBindLocale(locale);
      await _pumpReopen(
        tester,
        yildiznameFixtureNarrativeArtifact(),
        viewport: yildiznameVisualTextScaleViewport,
        textScale: yildiznameVisualTextScale,
      );
      expect(tester.takeException(), isNull);
      final note = tester.widget<StarMapScopeNote>(
        find.byType(StarMapScopeNote),
      );
      expect(find.text(note.disclosure.kicker), findsOneWidget);
      expect(find.text(note.disclosure.body), findsOneWidget);
      final size = tester.getSize(find.byType(StarMapScopeNote));
      expect(size.width, greaterThan(200));
    });
  }

  testWidgets('delta vs 7A unscoped baseline: chrome + note only', (
    tester,
  ) async {
    // Same prose through the pre-typed 7A path and the 7B production path.
    final artifact = yildiznameVisualNarrativeArtifact(
      id: 'yid_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      full: false,
    );
    await yildiznameGoldenPumpResult(
      tester,
      title: 'Yıldızname',
      sections: yildiznameVisualNarrativeReducedSections(),
    );
    final before = _visible(tester);
    expect(find.text('summary'), findsOneWidget, reason: '7A baseline defect');
    expect(find.byType(StarMapScopeNote), findsNothing);

    await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'tr',
      ),
    );
    final after = _visible(tester);
    expect(find.text('summary'), findsNothing);
    expect(find.byType(StarMapScopeNote), findsOneWidget);
    // Every prose body survives untouched.
    for (final body in const [
      'Güneş Leo konumunda sabırlı bir odak taşır.',
      'Kimlik alanında sakin bir netlik aranıyor.',
      'Bugün hangi odak sana daha dürüst geliyor?',
      'Yavaşça kendi ritmine dön.',
    ]) {
      expect(before.any((t) => t.contains(body)), isTrue, reason: body);
      expect(after.any((t) => t.contains(body)), isTrue, reason: body);
    }
    // Footer / disclaimer chrome is shared and unchanged.
    expect(find.byType(StarMapResultFooter), findsOneWidget);
    final delta = after.where((t) => !before.contains(t)).toSet();
    expect(
      delta,
      containsAll(<String>['Özet', 'Kimlik', 'Üzerine düşün', 'Kapanış']),
    );
  });
}
