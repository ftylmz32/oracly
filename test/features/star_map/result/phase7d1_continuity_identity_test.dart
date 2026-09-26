/// Phase 7D.1 — current-operation identity + owner firewall red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_projector.dart';

import '../artifacts/phase6_test_support.dart';

const _sabir = [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')];

Future<YildiznameArtifact> _mk(
  YildiznameNarrativeCompletionService service, {
  required String owner,
  required String idHint,
  required String? sem,
  DateTime? at,
  String summary = 'Okuma.',
}) {
  return service.complete(
    ownerId: owner,
    request: sampleRequest(themes: _sabir),
    result: sampleResult(themeRefs: const ['theme.0'], summary: summary),
    semanticFingerprint: sem,
    createdAtUtc: at,
  );
}

YildiznameArtifact _reown(YildiznameArtifact a, String ownerId) {
  return YildiznameArtifactFactory.createNarrative(
    ownerId: ownerId,
    id: a.id,
    request: sampleRequest(themes: _sabir),
    result: sampleResult(themeRefs: const ['theme.0'], summary: 'Owned.'),
    semanticFingerprint: a.semanticFingerprint,
    createdAtUtc: a.createdAtUtc,
  );
}

YildiznameArtifact _resign(
  YildiznameArtifact a, {
  String? semanticFingerprint,
  String? ownerId,
  String? id,
}) {
  return YildiznameArtifactFactory.createNarrative(
    ownerId: ownerId ?? a.ownerId,
    id: id ?? a.id,
    request: sampleRequest(themes: _sabir),
    result: sampleResult(themeRefs: const ['theme.0'], summary: 'Resealed.'),
    semanticFingerprint: semanticFingerprint,
    createdAtUtc: a.createdAtUtc,
  );
}

void main() {
  tearDown(resetIds);

  test('B 1 prior + current in history, fingerprint NULL → EMPTY', () async {
    useFixedIds(const [
      'yid_b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1',
      'yid_b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final prior = await _mk(
      service,
      owner: 'o1',
      idHint: 'p',
      sem: 'prior-sem',
      at: DateTime.utc(2026, 1, 1),
    );
    final raw = await _mk(
      service,
      owner: 'o1',
      idHint: 'c',
      sem: null,
      at: DateTime.utc(2026, 1, 2),
    );
    expect(raw.semanticFingerprint, isNull);
    final out = YildiznameContinuityProjector.project(
      current: raw,
      history: [prior, raw],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('C 1 prior + current in history, fingerprint blank → EMPTY', () async {
    useFixedIds(const [
      'yid_c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1',
      'yid_c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final prior = await _mk(
      service,
      owner: 'o1',
      idHint: 'p',
      sem: 'prior-sem',
      at: DateTime.utc(2026, 1, 1),
    );
    final raw = await _mk(
      service,
      owner: 'o1',
      idHint: 'c',
      sem: '',
      at: DateTime.utc(2026, 1, 2),
    );
    expect(raw.semanticFingerprint, '');
    final out = YildiznameContinuityProjector.project(
      current: raw,
      history: [prior, raw],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('A 1 prior + current in history, valid fingerprint → EMPTY', () async {
    useFixedIds(const [
      'yid_a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1',
      'yid_a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final prior = await _mk(
      service,
      owner: 'o1',
      idHint: 'p',
      sem: 'a-prior',
      at: DateTime.utc(2026, 1, 1),
    );
    final current = await _mk(
      service,
      owner: 'o1',
      idHint: 'c',
      sem: 'a-cur',
      at: DateTime.utc(2026, 1, 2),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [prior, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('D 2 valid prior + current same owner → continuity', () async {
    useFixedIds(const [
      'yid_d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1',
      'yid_d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2',
      'yid_d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _mk(
      service,
      owner: 'o1',
      idHint: 'a',
      sem: 'd-a',
      at: DateTime.utc(2026, 1, 1),
    );
    final b = await _mk(
      service,
      owner: 'o1',
      idHint: 'b',
      sem: 'd-b',
      at: DateTime.utc(2026, 1, 2),
    );
    final current = await _mk(
      service,
      owner: 'o1',
      idHint: 'c',
      sem: 'd-c',
      at: DateTime.utc(2026, 1, 3),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b, current],
      languageCode: 'tr',
    );
    expect(out.labels, ['Sabır']);
  });

  test('E Owner A priors + Owner B current → EMPTY', () async {
    useFixedIds(const [
      'yid_e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1',
      'yid_e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2',
      'yid_e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3',
    ]);
    final storage = fakeLocalStorage();
    final aRepo = artifactRepo(storage, 'ownerA');
    final aSvc = YildiznameNarrativeCompletionService(aRepo);
    final a1 = await _mk(
      aSvc,
      owner: 'ownerA',
      idHint: 'a1',
      sem: 'ea1',
      at: DateTime.utc(2026, 1, 1),
    );
    final a2 = await _mk(
      aSvc,
      owner: 'ownerA',
      idHint: 'a2',
      sem: 'ea2',
      at: DateTime.utc(2026, 1, 2),
    );
    final bRepo = artifactRepo(storage, 'ownerB');
    final bSvc = YildiznameNarrativeCompletionService(bRepo);
    final current = await _mk(
      bSvc,
      owner: 'ownerB',
      idHint: 'b',
      sem: 'eb',
      at: DateTime.utc(2026, 1, 3),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a1, a2, current],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('F mixed owners — only current owner history counts', () async {
    useFixedIds(const [
      'yid_f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1',
      'yid_f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2',
      'yid_f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3',
      'yid_f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4',
      'yid_f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5',
    ]);
    final storage = fakeLocalStorage();
    final aSvc = YildiznameNarrativeCompletionService(
      artifactRepo(storage, 'ownerA'),
    );
    final bSvc = YildiznameNarrativeCompletionService(
      artifactRepo(storage, 'ownerB'),
    );
    final a1 = await _mk(
      aSvc,
      owner: 'ownerA',
      idHint: 'a1',
      sem: 'fa1',
      at: DateTime.utc(2026, 1, 1),
    );
    final a2 = await _mk(
      aSvc,
      owner: 'ownerA',
      idHint: 'a2',
      sem: 'fa2',
      at: DateTime.utc(2026, 1, 2),
    );
    final b1 = await _mk(
      bSvc,
      owner: 'ownerB',
      idHint: 'b1',
      sem: 'fb1',
      at: DateTime.utc(2026, 1, 3),
    );
    final b2 = await _mk(
      bSvc,
      owner: 'ownerB',
      idHint: 'b2',
      sem: 'fb2',
      at: DateTime.utc(2026, 1, 4),
    );
    final current = await _mk(
      bSvc,
      owner: 'ownerB',
      idHint: 'bc',
      sem: 'fbc',
      at: DateTime.utc(2026, 1, 5),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a1, a2, b1, b2, current],
      languageCode: 'tr',
    );
    expect(out.labels, ['Sabır']);
  });

  test('G current owner blank → EMPTY', () async {
    useFixedIds(const [
      'yid_g1g1g1g1g1g1g1g1g1g1g1g1g1g1g1g1',
      'yid_g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2',
      'yid_g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3g3',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _mk(
      service,
      owner: 'o1',
      idHint: 'a',
      sem: 'ga',
      at: DateTime.utc(2026, 1, 1),
    );
    final b = await _mk(
      service,
      owner: 'o1',
      idHint: 'b',
      sem: 'gb',
      at: DateTime.utc(2026, 1, 2),
    );
    final current = await _mk(
      service,
      owner: 'o1',
      idHint: 'c',
      sem: 'gc',
      at: DateTime.utc(2026, 1, 3),
    );
    final blank = _reown(current, '   ');
    final out = YildiznameContinuityProjector.project(
      current: blank,
      history: [a, b, blank],
      languageCode: 'tr',
    );
    expect(out.isEmpty, isTrue);
  });

  test('H same semanticFingerprint different IDs → excluded', () async {
    useFixedIds(const [
      'yid_h1h1h1h1h1h1h1h1h1h1h1h1h1h1h1h1',
      'yid_h2h2h2h2h2h2h2h2h2h2h2h2h2h2h2h2',
      'yid_h3h3h3h3h3h3h3h3h3h3h3h3h3h3h3h3',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final prior = await _mk(
      service,
      owner: 'o1',
      idHint: 'p',
      sem: 'unique-prior',
      at: DateTime.utc(2026, 1, 1),
    );
    final twinA = await _mk(
      service,
      owner: 'o1',
      idHint: 't1',
      sem: 'same-op',
      at: DateTime.utc(2026, 1, 2),
      summary: 'Twin A.',
    );
    // Second row with same semantic fingerprint cannot be saved via complete
    // (dedupe). Reseal under a new id for projector-level history injection.
    final twinB = _resign(
      twinA,
      id: 'yid_h3h3h3h3h3h3h3h3h3h3h3h3h3h3h3h3',
      semanticFingerprint: 'same-op',
    );
    final out = YildiznameContinuityProjector.project(
      current: twinA,
      history: [prior, twinA, twinB],
      languageCode: 'tr',
    );
    // Only one true prior remains after ID + semantic exclusion.
    expect(out.isEmpty, isTrue);
  });

  test('I current absent from history, 2 priors → continuity', () async {
    useFixedIds(const [
      'yid_i1i1i1i1i1i1i1i1i1i1i1i1i1i1i1i1',
      'yid_i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2',
      'yid_i3i3i3i3i3i3i3i3i3i3i3i3i3i3i3i3',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _mk(
      service,
      owner: 'o1',
      idHint: 'a',
      sem: 'ia',
      at: DateTime.utc(2026, 1, 1),
    );
    final b = await _mk(
      service,
      owner: 'o1',
      idHint: 'b',
      sem: 'ib',
      at: DateTime.utc(2026, 1, 2),
    );
    final current = await _mk(
      service,
      owner: 'o1',
      idHint: 'c',
      sem: 'ic',
      at: DateTime.utc(2026, 1, 3),
    );
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [a, b], // current intentionally omitted
      languageCode: 'tr',
    );
    expect(out.labels, ['Sabır']);
  });

  test('G whitespace owner on history still matches via trim', () async {
    useFixedIds(const [
      'yid_w1w1w1w1w1w1w1w1w1w1w1w1w1w1w1w1',
      'yid_w2w2w2w2w2w2w2w2w2w2w2w2w2w2w2w2',
      'yid_w3w3w3w3w3w3w3w3w3w3w3w3w3w3w3w3',
    ]);
    final repo = artifactRepo(fakeLocalStorage(), 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await _mk(
      service,
      owner: 'o1',
      idHint: 'a',
      sem: 'wa',
      at: DateTime.utc(2026, 1, 1),
    );
    final b = await _mk(
      service,
      owner: 'o1',
      idHint: 'b',
      sem: 'wb',
      at: DateTime.utc(2026, 1, 2),
    );
    final current = await _mk(
      service,
      owner: 'o1',
      idHint: 'c',
      sem: 'wc',
      at: DateTime.utc(2026, 1, 3),
    );
    final paddedA = _reown(a, '  o1  ');
    final paddedB = _reown(b, ' o1');
    final out = YildiznameContinuityProjector.project(
      current: current,
      history: [paddedA, paddedB, current],
      languageCode: 'tr',
    );
    expect(out.labels, ['Sabır']);
  });
}
