/// Extracted live/cache cases (file-size budget).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_cache.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_live_failure.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_live_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_factory.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'corpus/narrative_fail_corpus.dart';
import 'corpus/narrative_result_corpus.dart';
import 'fixtures/fake_yildizname_ai.dart';
import 'fixtures/narrative_evidence_fixtures.dart';

abstract final class NarrativeLiveCacheCases {
  NarrativeLiveCacheCases._();

  static Future<void> twoAttemptSuccess() async {
    final request = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      languageCode: 'en',
    );
    var n = 0;
    final ai = FakeYildiznameAi(({
      required payload,
      required fingerprint,
      required attempt,
    }) async {
      n++;
      if (attempt == 1) {
        return okMap(NarrativeFailCorpus.wrongMoonSign());
      }
      return okMap(NarrativeResultCorpus.fullEn());
    });
    final service = YildiznameNarrativeLiveService(
      ai: ai,
      enforceFlag: false,
    );
    final result = await service.generate(request: request);
    expect(result.languageCode, 'en');
    expect(n, 2);
    expect(ai.calls, hasLength(2));
  }

  static Future<void> cacheLifecycle() async {
    final request = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      languageCode: 'en',
    );
    final fp = YildiznameRequestFingerprint.of(request);
    final cache = YildiznameNarrativeCache();
    final bad = YildiznameResultParser.parse(NarrativeFailCorpus.wrongMoonSign());
    expect(
      () => cache.putApproved(
        fingerprint: fp,
        request: request,
        result: bad,
      ),
      throwsA(isA<YildiznameResultException>()),
    );
    expect(cache.length, 0);

    final good = YildiznameResultParser.parse(NarrativeResultCorpus.fullEn());
    cache.putApproved(fingerprint: fp, request: request, result: good);
    expect(cache.get(fp), isNotNull);
    expect(
      cache.getRevalidated(fingerprint: fp, request: request),
      isNotNull,
    );

    final service = YildiznameNarrativeLiveService(
      ai: FakeYildiznameAi(({
        required payload,
        required fingerprint,
        required attempt,
      }) async =>
          okMap(NarrativeFailCorpus.wrongMoonSign())),
      cache: cache,
      enforceFlag: false,
    );
    cache.invalidate(fp);
    await expectLater(
      service.generate(request: request, forceRefresh: true),
      throwsA(isA<YildiznameLiveFailure>()),
    );
    expect(cache.get(fp), isNull);
  }
}
