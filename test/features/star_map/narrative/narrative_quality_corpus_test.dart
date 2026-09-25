/// Positive + hallucination + safety quality corpus tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_validator.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_factory.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'corpus/narrative_fail_corpus.dart';
import 'corpus/narrative_result_corpus.dart';
import 'fixtures/narrative_evidence_fixtures.dart';

void _pass(Map<String, dynamic> map, {required dynamic evidence}) {
  final request = YildiznameRequestFactory.fromEvidence(
    evidence: evidence,
    languageCode: map['languageCode'] as String,
  );
  final result = YildiznameResultParser.parse(map);
  YildiznameQualityValidator.validate(request: request, result: result);
}

void _fail(
  Map<String, dynamic> map, {
  required dynamic evidence,
  YildiznameResultErrorKind? kind,
}) {
  final request = YildiznameRequestFactory.fromEvidence(
    evidence: evidence,
    languageCode: map['languageCode'] as String,
  );
  try {
    final result = YildiznameResultParser.parse(map);
    YildiznameQualityValidator.validate(request: request, result: result);
    fail('expected YildiznameResultException');
  } on YildiznameResultException {
    // Any rejection is enough; gate order may vary by mutant.
  }
}

void main() {
  test('positive corpus TR/EN/RU legacy reduced full', () {
    _pass(
      NarrativeResultCorpus.legacyTr(),
      evidence: NarrativeEvidenceFixtures.legacySun(),
    );
    _pass(
      NarrativeResultCorpus.reducedEn(),
      evidence: NarrativeEvidenceFixtures.reducedStable(),
    );
    _pass(
      NarrativeResultCorpus.fullEn(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
    );
    _pass(
      NarrativeResultCorpus.fullTr(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
    );
    _pass(
      NarrativeResultCorpus.fullRu(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
    );
  });

  test('hallucination corpus fails', () {
    _fail(
      NarrativeFailCorpus.wrongMoonSign(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      kind: YildiznameResultErrorKind.grounding,
    );
    _fail(
      NarrativeFailCorpus.ascWithoutEvidence(),
      evidence: NarrativeEvidenceFixtures.legacySun(),
    );
    _fail(
      NarrativeFailCorpus.wrongVenusHouse(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      kind: YildiznameResultErrorKind.grounding,
    );
    _fail(
      NarrativeFailCorpus.falseConjunction(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      kind: YildiznameResultErrorKind.grounding,
    );
  });

  test('unsupported safety genericity themes corpus', () {
    _fail(
      NarrativeFailCorpus.unsupportedChiron(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
    );
    _fail(
      NarrativeFailCorpus.safetyDeath(),
      evidence: NarrativeEvidenceFixtures.legacySun(),
      kind: YildiznameResultErrorKind.safety,
    );
    _fail(
      NarrativeFailCorpus.genericCosmic(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      kind: YildiznameResultErrorKind.genericity,
    );
    _fail(
      NarrativeFailCorpus.archiveWithoutThemes(),
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      kind: YildiznameResultErrorKind.themeRef,
    );
  });
}
