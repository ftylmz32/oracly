/// Phase 7D continuity projector — verified intersection only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_source.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_theme_identity.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_projector.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_chrome.dart';

import '../artifacts/phase6_test_support.dart';

Future<YildiznameArtifact> _complete(
  YildiznameNarrativeCompletionService service, {
  required String owner,
  required String sem,
  required List<YildiznameThemeFact> themes,
  required List<String> accepted,
  String summary = 'Okuma.',
  DateTime? at,
}) {
  return service.complete(
    ownerId: owner,
    request: sampleRequest(themes: themes),
    result: sampleResult(themeRefs: accepted, summary: summary),
    semanticFingerprint: sem,
    createdAtUtc: at,
  );
}

void main() {
  tearDown(resetIds);

  test('A legacy current → empty continuity', () {
    final legacy = YildiznameArtifactFactory.createLegacy(
      ownerId: 'o1',
      title: 'Gökyüzü',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: const [],
      sunSignId: 'leo',
      dayKey: '2026-01-10',
      createdAtUtc: DateTime.utc(2026, 1, 10),
    );
    final out = YildiznameContinuityProjector.project(
      current: legacy,
      history: const [],
      languageCode: 'tr',
    );
    expect(out, YildiznameContinuityPresentation.empty);
  });

  test('B narrative + no history → empty', () async {
    useFixedIds(const ['yid_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb']);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: const [],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('C one prior matching → empty (support < 2)', () async {
    useFixedIds(const [
      'yid_c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1',
      'yid_c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final prior = await _complete(
      service,
      owner: 'o1',
      sem: 'p1',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
      at: DateTime.utc(2026, 1, 1),
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
      at: DateTime.utc(2026, 1, 2),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [prior, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('D two prior + current accepts Sabır → shows Sabır', () async {
    useFixedIds(const [
      'yid_d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1',
      'yid_d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2',
      'yid_d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _complete(
      service,
      owner: 'o1',
      sem: 'a',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
      at: DateTime.utc(2026, 1, 1),
    );
    final b = await _complete(
      service,
      owner: 'o1',
      sem: 'b',
      themes: const [YildiznameThemeFact(themeRef: 'theme.1', label: 'Sabır')],
      accepted: const ['theme.1'],
      at: DateTime.utc(2026, 1, 2),
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
      at: DateTime.utc(2026, 1, 3),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b, current],
      languageCode: 'tr',
    );
    expect(out.isNotEmpty, isTrue);
    expect(out.labels, ['Sabır']);
    expect(out.heading, YildiznameResultChrome.continuityHeading('tr'));
    expect(out.body, YildiznameResultChrome.continuityBody('tr'));
    expect(out.heading.contains('yth_'), isFalse);
    expect(out.body.contains('theme.'), isFalse);
  });

  test('E two prior Sabır + current does NOT accept → empty', () async {
    useFixedIds(const [
      'yid_e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1',
      'yid_e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2',
      'yid_e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _complete(
      service,
      owner: 'o1',
      sem: 'a',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final b = await _complete(
      service,
      owner: 'o1',
      sem: 'b',
      themes: const [YildiznameThemeFact(themeRef: 'theme.1', label: 'Sabır')],
      accepted: const ['theme.1'],
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
        YildiznameThemeFact(themeRef: 'theme.1', label: 'Kariyer'),
      ],
      accepted: const ['theme.1'], // only Kariyer accepted
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('F discoveryThemes has Sabır but result rejects → empty', () async {
    useFixedIds(const [
      'yid_f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1',
      'yid_f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2',
      'yid_f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _complete(
      service,
      owner: 'o1',
      sem: 'a',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final b = await _complete(
      service,
      owner: 'o1',
      sem: 'b',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const [], // not accepted
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test(
    'G Personal-Discovery origin Sabır accepted + prior recurrence → shows',
    () async {
      useFixedIds(const [
        'yid_g1g1g1g1g1g1g1g1g1g1g1g1g1g1g1g1',
        'yid_g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2',
        'yid_g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3',
      ]);
      final storage = fakeLocalStorage();
      final repo = artifactRepo(storage, 'o1');
      final service = YildiznameNarrativeCompletionService(repo);
      final a = await _complete(
        service,
        owner: 'o1',
        sem: 'a',
        themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
        accepted: const ['theme.0'],
      );
      final b = await _complete(
        service,
        owner: 'o1',
        sem: 'b',
        themes: const [YildiznameThemeFact(themeRef: 'theme.2', label: 'Sabır')],
        accepted: const ['theme.2'],
      );
      // Current request looks like merged PD + archive, but identity is label.
      final current = await _complete(
        service,
        owner: 'o1',
        sem: 'cur',
        themes: const [
          YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
        ],
        accepted: const ['theme.0'],
      );
      final out = YildiznameContinuityProjector.project(
        current: current,
        history: [a, b, current],
        languageCode: 'tr',
      );
      expect(out.labels, ['Sabır']);
    },
  );

  test('H same theme.0 different labels → no false match', () async {
    useFixedIds(const [
      'yid_h1h1h1h1h1h1h1h1h1h1h1h1h1h1h1h1',
      'yid_h2h2h2h2h2h2h2h2h2h2h2h2h2h2h2h2',
      'yid_h3h3h3h3h3h3h3h3h3h3h3h3h3h3h3h3',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _complete(
      service,
      owner: 'o1',
      sem: 'a',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final b = await _complete(
      service,
      owner: 'o1',
      sem: 'b',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Kariyer')],
      accepted: const ['theme.0'],
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('I different refs same label → valid', () async {
    useFixedIds(const [
      'yid_i1i1i1i1i1i1i1i1i1i1i1i1i1i1i1i1',
      'yid_i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2',
      'yid_i3i3i3i3i3i3i3i3i3i3i3i3i3i3i3i3',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _complete(
      service,
      owner: 'o1',
      sem: 'a',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final b = await _complete(
      service,
      owner: 'o1',
      sem: 'b',
      themes: const [YildiznameThemeFact(themeRef: 'theme.9', label: 'Sabır')],
      accepted: const ['theme.9'],
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.3', label: 'Sabır')],
      accepted: const ['theme.3'],
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b, current],
      languageCode: 'en',
    );
    expect(out.labels, ['Sabır']);
    expect(out.heading, YildiznameResultChrome.continuityHeading('en'));
  });

  test('J unknown current accepted themeRef → ignored', () async {
    useFixedIds(const [
      'yid_j1j1j1j1j1j1j1j1j1j1j1j1j1j1j1j1',
      'yid_j2j2j2j2j2j2j2j2j2j2j2j2j2j2j2j2',
      'yid_j3j3j3j3j3j3j3j3j3j3j3j3j3j3j3j3',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _complete(
      service,
      owner: 'o1',
      sem: 'a',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final b = await _complete(
      service,
      owner: 'o1',
      sem: 'b',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.7'], // unknown vs request
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('K duplicate labels in one prior → one support; needs 2 artifacts',
      () async {
    useFixedIds(const [
      'yid_k1k1k1k1k1k1k1k1k1k1k1k1k1k1k1k1',
      'yid_k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final prior = await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
        YildiznameThemeFact(themeRef: 'theme.1', label: ' sabır '),
      ]),
      result: sampleResult(themeRefs: const ['theme.0', 'theme.1']),
      semanticFingerprint: 'dup',
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [prior, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('L legacy historical never counts', () async {
    useFixedIds(const [
      'yid_l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1',
      'yid_l2l2l2l2l2l2l2l2l2l2l2l2l2l2l2l2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final legacy = YildiznameArtifactFactory.createLegacy(
      ownerId: 'o1',
      id: 'yid_legacylegacylegacylegacylegacy00',
      title: 'Gökyüzü',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: const [],
      sunSignId: 'leo',
      dayKey: '2026-01-01',
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );
    await repo.saveNew(legacy);
    final prior = await _complete(
      service,
      owner: 'o1',
      sem: 'p',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [legacy, prior, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
    expect(legacy.source, YildiznameArtifactSource.legacyLocal);
  });

  test('M current operation excluded from prior threshold', () async {
    useFixedIds(const [
      'yid_m1m1m1m1m1m1m1m1m1m1m1m1m1m1m1m1',
      'yid_m2m2m2m2m2m2m2m2m2m2m2m2m2m2m2m2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final prior = await _complete(
      service,
      owner: 'o1',
      sem: 'p',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'cur',
      themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      accepted: const ['theme.0'],
    );
    // Only one distinct prior when current fingerprint is excluded.
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [prior, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('P/Q ordering + max 3 cap', () async {
    useFixedIds([
      for (var i = 0; i < 10; i++)
        'yid_${i.toRadixString(16).padLeft(32, '0')}',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    Future<YildiznameArtifact> mk(
      String sem,
      String label,
      String ref,
      DateTime at,
    ) =>
        _complete(
          service,
          owner: 'o1',
          sem: sem,
          themes: [YildiznameThemeFact(themeRef: ref, label: label)],
          accepted: [ref],
          at: at,
        );
    // Sabır support 3, Kariyer 2, Dengе 2
    final a1 = await mk('s1', 'Sabır', 'theme.0', DateTime.utc(2026, 1, 1));
    final a2 = await mk('s2', 'Sabır', 'theme.0', DateTime.utc(2026, 1, 2));
    final a3 = await mk('s3', 'Sabır', 'theme.0', DateTime.utc(2026, 1, 3));
    final b1 = await mk('k1', 'Kariyer', 'theme.1', DateTime.utc(2026, 1, 4));
    final b2 = await mk('k2', 'Kariyer', 'theme.1', DateTime.utc(2026, 1, 5));
    final c1 = await mk('d1', 'Denge', 'theme.2', DateTime.utc(2026, 1, 6));
    final c2 = await mk('d2', 'Denge', 'theme.2', DateTime.utc(2026, 1, 7));
    final extra = await mk('x1', 'Umut', 'theme.3', DateTime.utc(2026, 1, 8));
    final extra2 = await mk('x2', 'Umut', 'theme.3', DateTime.utc(2026, 1, 9));
    final current = await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
        YildiznameThemeFact(themeRef: 'theme.1', label: 'Kariyer'),
        YildiznameThemeFact(themeRef: 'theme.2', label: 'Denge'),
        YildiznameThemeFact(themeRef: 'theme.3', label: 'Umut'),
      ]),
      result: sampleResult(
        themeRefs: const ['theme.0', 'theme.1', 'theme.2', 'theme.3'],
      ),
      semanticFingerprint: 'cur',
      createdAtUtc: DateTime.utc(2026, 1, 10),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a1, a2, a3, b1, b2, c1, c2, extra, extra2, current],
      languageCode: 'tr',
    );
    expect(out.labels.length, YildiznameContinuityProjector.maxThemes);
    expect(out.labels.first, 'Sabır');
    expect(
      out.labels,
      everyElement(isNot(contains('yth_'))),
    );
    expect(
      YildiznameThemeIdentity.keyFor('Sabır').startsWith('yth_'),
      isTrue,
    );
  });

  test('Personal Discovery only (no prior Yıldızname recurrence) → empty',
      () async {
    useFixedIds(const ['yid_pdpdpdpdpdpdpdpdpdpdpdpdpdpdpdpd']);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final current = await _complete(
      service,
      owner: 'o1',
      sem: 'pd-only',
      themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
      ],
      accepted: const ['theme.0'],
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('R presentation never exposes internal IDs', () {
    const c = YildiznameContinuityPresentation(
      heading: 'Arşiv yankısı',
      body: 'Bu temalar önceki Yıldızname okumalarında da tekrar etmişti.',
      labels: ['Sabır', 'Kariyer'],
    );
    final blob = '${c.heading}|${c.body}|${c.labels.join('|')}';
    for (final bad in const [
      'theme.',
      'yth_',
      'sourceArtifact',
      'semanticFingerprint',
      'evidenceFingerprint',
      'supportCount',
    ]) {
      expect(blob.contains(bad), isFalse, reason: bad);
    }
  });
}
