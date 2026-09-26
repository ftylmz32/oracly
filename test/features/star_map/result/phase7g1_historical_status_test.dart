/// Phase 7G.1 — historical reopen chrome source matrix (test-only).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_historical_status.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_historical_status.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_phase7g_fixtures.dart';
import '../../../visual/yildizname/yildizname_phase7g_pump.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  test('A legacyLive null id — no historical status', () {
    final p = YildiznameResultPresentation.legacyLive(
      title: 'T',
      sections: const [],
    );
    expect(p.historicalStatus, isNull);
  });

  test('B legacyLive with id+time — still live, no historical', () {
    final p = YildiznameResultPresentation.legacyLive(
      title: 'T',
      sections: const [],
      artifactId: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      createdAtUtc: DateTime.utc(2026, 7, 2),
    );
    expect(p.source, YildiznameResultSource.legacyLive);
    expect(p.historicalStatus, isNull);
  });

  test('C legacyArtifact — status + stored date', () {
    final p = phase7gLegacyArtifactReopen();
    expect(p.source.isArtifact, isTrue);
    expect(p.historicalStatus, isNotNull);
    expect(p.historicalStatus!.label, 'Kayıtlı yorum');
    expect(p.historicalStatus!.formattedDate, contains('2026'));
  });

  test('D narrativeLive with id+time — no historical', () {
    final p = phase7gLiveAndArtifact().live;
    expect(p.source, YildiznameResultSource.narrativeLive);
    expect(p.artifactId, isNotNull);
    expect(p.createdAtUtc, isNotNull);
    expect(p.historicalStatus, isNull);
  });

  test('E narrativeArtifact — status present', () {
    final p = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        createdAtUtc: DateTime.utc(2026, 7, 4),
      ),
      chromeLocale: 'tr',
    );
    expect(p.historicalStatus, isNotNull);
    expect(p.historicalStatus!.line, startsWith('Kayıtlı yorum ·'));
  });

  test('F artifact source missing createdAt — fail closed', () {
    expect(
      YildiznameHistoricalStatus.tryOf(
        source: YildiznameResultSource.narrativeArtifact,
        createdAtUtc: null,
        languageCode: 'tr',
      ),
      isNull,
    );
  });

  test('G reopen twice — identical status', () {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 3, 3),
    );
    final a =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final b =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    expect(a.historicalStatus, b.historicalStatus);
  });

  test('I/J/K locale chrome over TR prose', () {
    final artifact = yildiznameFixtureNarrativeArtifact(
      languageCode: 'tr',
      summary: 'Güneş sabırlı duruyor.',
      createdAtUtc: DateTime.utc(2026, 7, 2),
    );
    final tr =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final en =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'en');
    final ru =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'ru');
    expect(tr.historicalStatus!.label, 'Kayıtlı yorum');
    expect(en.historicalStatus!.label, 'Saved reading');
    expect(ru.historicalStatus!.label, 'Сохранённое толкование');
    expect(tr.sections.first.body, contains('Güneş'));
    expect(en.sections.first.body, contains('Güneş'));
    expect(ru.sections.first.body, contains('Güneş'));
  });

  testWidgets('widget appears only for artifact', (tester) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 7, 2),
    );
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualCanonicalViewport,
      storage: storage,
      child: StarMapReferenceResultScreen(
        presentation: YildiznameArtifactPresentation.of(
          artifact,
          chromeLocale: 'tr',
        ),
      ),
    );
    expect(find.byType(StarMapHistoricalStatus), findsOneWidget);
    expect(find.textContaining('Kayıtlı yorum'), findsOneWidget);
  });

  test('forensic hide suppresses status', () {
    final p = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        createdAtUtc: DateTime.utc(2026, 7, 2),
      ),
      chromeLocale: 'tr',
    ).withForensicHideHistoricalStatus();
    expect(p.historicalStatus, isNull);
  });

  test('status never embeds raw ids', () {
    final p = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        id: 'yid_cccccccccccccccdddddddddddddddd',
        createdAtUtc: DateTime.utc(2026, 7, 2),
      ),
      chromeLocale: 'tr',
    );
    final line = p.historicalStatus!.line;
    for (final bad in const [
      'yid_',
      'ownerId',
      'semanticFingerprint',
      'evidenceFingerprint',
      'contentHash',
      'serializerVersion',
    ]) {
      expect(line.contains(bad), isFalse, reason: bad);
    }
  });
}
