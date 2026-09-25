/// Live two-attempt, cache, parser strictness, validator order.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_live_failure.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_live_service.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_validator.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_factory.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'corpus/narrative_result_corpus.dart';
import 'fixtures/fake_yildizname_ai.dart';
import 'fixtures/narrative_evidence_fixtures.dart';
import 'narrative_live_cache_cases.dart';

void main() {
  test('parser rejects unknown keys and bad kinds', () {
    final bad = Map<String, dynamic>.from(NarrativeResultCorpus.legacyTr());
    bad['extra'] = true;
    expect(
      () => YildiznameResultParser.parse(bad),
      throwsA(isA<YildiznameResultException>().having(
        (e) => e.kind,
        'kind',
        YildiznameResultErrorKind.unknownKey,
      )),
    );
    final kind = Map<String, dynamic>.from(NarrativeResultCorpus.legacyTr());
    final sections = List<Map<String, dynamic>>.from(
      (kind['sections'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    sections[0] = {...sections[0], 'kind': 'not_a_kind'};
    kind['sections'] = sections;
    expect(
      () => YildiznameResultParser.parse(kind),
      throwsA(isA<YildiznameResultException>().having(
        (e) => e.kind,
        'kind',
        YildiznameResultErrorKind.unknownKind,
      )),
    );
  });

  test('validator stage order is documented', () {
    expect(YildiznameQualityValidator.stageOrder.first, 'contract');
    expect(YildiznameQualityValidator.stageOrder.contains('grounding'), isTrue);
    expect(YildiznameQualityValidator.stageOrder.last, 'coverage');
  });

  test('two-attempt scripted fake AI then success', () async {
    await NarrativeLiveCacheCases.twoAttemptSuccess();
  });

  test('cache rejects bad; stores good; invalidates mutant', () async {
    await NarrativeLiveCacheCases.cacheLifecycle();
  });

  test('flag-disabled live path fails closed', () async {
    final request = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.legacySun(),
      languageCode: 'tr',
    );
    final service = YildiznameNarrativeLiveService(
      ai: FakeYildiznameAi(({
        required payload,
        required fingerprint,
        required attempt,
      }) async =>
          AiOutcome.success(NarrativeResultCorpus.legacyTr())),
      enforceFlag: true,
    );
    await expectLater(
      service.generate(request: request),
      throwsA(isA<YildiznameLiveFailure>().having(
        (e) => e.kind,
        'kind',
        YildiznameLiveFailureKind.flagDisabled,
      )),
    );
  });
}
