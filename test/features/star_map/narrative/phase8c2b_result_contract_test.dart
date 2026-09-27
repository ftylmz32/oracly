/// Phase 8C.2b — the client result contract equals the FROZEN Phase 5 shape.
///
/// summary = block · sections = blocks · reflectionPrompt = string | null ·
/// closingMessage = string. The frozen doc, `narrative-yildizname-result.ts`
/// and the deployed candidate all agree; the client used to demand blocks for
/// reflection / closing, which rejected every real backend response.
/// All content here is synthetic.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_integrity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_reopen.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_payload.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_prose.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_section.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../artifacts/phase6_test_support.dart';

/// A backend-shaped (frozen) result map. Overrides replace whole fields.
Map<String, dynamic> _backendResult({
  Object? reflectionPrompt = 'Which habit feeds you slowly but surely?',
  Object? closingMessage = 'Come back to your own rhythm whenever you like.',
  bool omitReflection = false,
  bool omitClosing = false,
}) {
  final map = <String, dynamic>{
    'contractVersion': kYildiznameResultContractVersion,
    'languageCode': 'en',
    'scope': 'reduced',
    'summary': {
      'text':
          'A steady sense of focus runs through this reading, held lightly.',
      'factRefs': ['place.sun.leo'],
      'themeRefs': <String>['theme.0'],
    },
    'sections': [
      {
        'kind': 'core_identity',
        'text':
            'Identity here reads as patient and warm, without hurry or force.',
        'factRefs': ['place.sun.leo'],
        'themeRefs': <String>[],
      },
    ],
    'reflectionPrompt': reflectionPrompt,
    'closingMessage': closingMessage,
  };
  if (omitReflection) map.remove('reflectionPrompt');
  if (omitClosing) map.remove('closingMessage');
  return map;
}

Matcher _resultError(YildiznameResultErrorKind kind, [String? message]) =>
    throwsA(
      isA<YildiznameResultException>()
          .having((e) => e.kind, 'kind', kind)
          .having(
            (e) => e.message,
            'message',
            message == null ? anything : equals(message),
          ),
    );

void main() {
  group('parser — frozen shape', () {
    test('reflectionPrompt string + closingMessage string → PASS', () {
      final r = YildiznameResultParser.parse(_backendResult());
      expect(r.reflectionPrompt, 'Which habit feeds you slowly but surely?');
      expect(
        r.closingMessage,
        'Come back to your own rhythm whenever you like.',
      );
      expect(r.summary.factRefs, ['place.sun.leo']);
      expect(r.sections.single.text, contains('patient and warm'));
    });

    test('reflectionPrompt null → PASS and stays null', () {
      final r = YildiznameResultParser.parse(
        _backendResult(reflectionPrompt: null),
      );
      expect(r.reflectionPrompt, isNull);
      expect(r.visibleProse.contains('null'), isFalse);
    });

    test('reflection / closing are bounded exactly at the client limits', () {
      expect(
        YildiznameResultParser.parse(
          _backendResult(
            reflectionPrompt: 'r' * kYildiznameMaxReflectionChars,
            closingMessage: 'c' * kYildiznameMaxClosingChars,
          ),
        ).closingMessage.length,
        kYildiznameMaxClosingChars,
      );
      expect(
        () => YildiznameResultParser.parse(
          _backendResult(
            reflectionPrompt: 'r' * (kYildiznameMaxReflectionChars + 1),
          ),
        ),
        _resultError(YildiznameResultErrorKind.bounds, 'reflectionPrompt'),
      );
      expect(
        () => YildiznameResultParser.parse(
          _backendResult(
            closingMessage: 'c' * (kYildiznameMaxClosingChars + 1),
          ),
        ),
        _resultError(YildiznameResultErrorKind.bounds, 'closingMessage'),
      );
    });

    test(
      'a short but real string is valid (backend only requires non-empty)',
      () {
        final r = YildiznameResultParser.parse(
          _backendResult(reflectionPrompt: 'Why?', closingMessage: 'Rest.'),
        );
        expect(r.reflectionPrompt, 'Why?');
        expect(r.closingMessage, 'Rest.');
      },
    );

    test(
      'empty / blank strings are rejected (backend nullable / nonEmpty)',
      () {
        for (final blank in const ['', '   ', '\n']) {
          expect(
            () => YildiznameResultParser.parse(
              _backendResult(reflectionPrompt: blank),
            ),
            _resultError(YildiznameResultErrorKind.bounds, 'reflectionPrompt'),
            reason: 'reflection "${blank.replaceAll('\n', r'\n')}"',
          );
          expect(
            () => YildiznameResultParser.parse(
              _backendResult(closingMessage: blank),
            ),
            _resultError(YildiznameResultErrorKind.bounds, 'closingMessage'),
          );
        }
      },
    );

    test('closingMessage may NOT be null; both keys are required', () {
      expect(
        () =>
            YildiznameResultParser.parse(_backendResult(closingMessage: null)),
        _resultError(YildiznameResultErrorKind.schema, 'type:closingMessage'),
      );
      expect(
        () => YildiznameResultParser.parse(_backendResult(omitClosing: true)),
        _resultError(
          YildiznameResultErrorKind.schema,
          'missing:closingMessage',
        ),
      );
      expect(
        () =>
            YildiznameResultParser.parse(_backendResult(omitReflection: true)),
        _resultError(
          YildiznameResultErrorKind.schema,
          'missing:reflectionPrompt',
        ),
      );
    });

    test('non-string values are rejected', () {
      for (final bad in <Object>[
        7,
        true,
        <String>['x'],
        1.5,
      ]) {
        expect(
          () => YildiznameResultParser.parse(
            _backendResult(reflectionPrompt: bad),
          ),
          _resultError(
            YildiznameResultErrorKind.schema,
            'type:reflectionPrompt',
          ),
        );
        expect(
          () =>
              YildiznameResultParser.parse(_backendResult(closingMessage: bad)),
          _resultError(YildiznameResultErrorKind.schema, 'type:closingMessage'),
        );
      }
    });

    test('the OLD client-only block form is NOT the provider contract', () {
      // The live parser must never redefine the frozen contract around it.
      final block = {
        'text': 'Which habit feeds you slowly but surely?',
        'factRefs': <String>[],
        'themeRefs': <String>[],
      };
      expect(
        () => YildiznameResultParser.parse(
          _backendResult(reflectionPrompt: block),
        ),
        _resultError(YildiznameResultErrorKind.schema, 'type:reflectionPrompt'),
      );
      expect(
        () =>
            YildiznameResultParser.parse(_backendResult(closingMessage: block)),
        _resultError(YildiznameResultErrorKind.schema, 'type:closingMessage'),
      );
    });

    test('unknown root keys are still rejected', () {
      final m = _backendResult()..['extra'] = 'x';
      expect(
        () => YildiznameResultParser.parse(m),
        _resultError(YildiznameResultErrorKind.unknownKey, 'extra'),
      );
    });
  });

  group('refs and prose — reflection / closing own no evidence', () {
    final result = YildiznameNarrativeStructuredResult(
      contractVersion: kYildiznameResultContractVersion,
      languageCode: 'en',
      scope: YildiznameNarrativeScope.reduced,
      summary: YildiznameNarrativeBlock(
        text: 'Summary text that carries refs.',
        factRefs: const ['placement.sun'],
        themeRefs: const ['theme.0'],
      ),
      sections: [
        YildiznameNarrativeSection(
          kind: YildiznameSectionKind.coreIdentity,
          text: 'Section text that carries refs.',
          factRefs: const ['placement.moon'],
          themeRefs: const ['theme.1'],
        ),
      ],
      reflectionPrompt: 'Reflection prose.',
      closingMessage: 'Closing prose.',
    );

    test('allFactRefs / allThemeRefs come only from summary + sections', () {
      expect(result.allFactRefs.toList(), ['placement.sun', 'placement.moon']);
      expect(result.allThemeRefs.toList(), ['theme.0', 'theme.1']);
    });

    test('visibleProse has every string, and no literal "null"', () {
      expect(result.visibleProse, contains('Reflection prose.'));
      expect(result.visibleProse, contains('Closing prose.'));
      final none = YildiznameNarrativeStructuredResult(
        contractVersion: result.contractVersion,
        languageCode: 'en',
        scope: result.scope,
        summary: result.summary,
        sections: result.sections,
        reflectionPrompt: null,
        closingMessage: 'Closing prose.',
      );
      expect(none.visibleProse.contains('null'), isFalse);
      expect(none.visibleProse, contains('Closing prose.'));
      final blank = YildiznameNarrativeStructuredResult(
        contractVersion: result.contractVersion,
        languageCode: 'en',
        scope: result.scope,
        summary: result.summary,
        sections: result.sections,
        reflectionPrompt: '   ',
        closingMessage: 'Closing prose.',
      );
      expect(
        blank.visibleProse.split('\n').where((l) => l.trim().isEmpty).length,
        lessThanOrEqualTo(1),
      );
    });

    test('quality guards use the string closing (summary == closing)', () {
      final same = YildiznameNarrativeStructuredResult(
        contractVersion: result.contractVersion,
        languageCode: 'en',
        scope: result.scope,
        summary: YildiznameNarrativeBlock(
          text: 'The very same sentence twice over.',
          factRefs: const ['place.sun.leo'],
          themeRefs: const [],
        ),
        sections: result.sections,
        reflectionPrompt: null,
        closingMessage: 'The very same sentence twice over.',
      );
      expect(
        () => YildiznameQualityProse.validate(sampleRequest(), same),
        _resultError(YildiznameResultErrorKind.prose, 'duplicateParagraph'),
      );
    });
  });

  group('canonical artifact shape + exact reopen', () {
    test('payload stores string|null + string, never blocks', () {
      final withReflection = YildiznameNarrativePayload.resultToMap(
        sampleResult(),
      );
      expect(withReflection['reflectionPrompt'], isA<String>());
      expect(withReflection['closingMessage'], isA<String>());
      expect(withReflection['summary'], isA<Map>());
      expect(
        (withReflection['sections'] as List).every((s) => s is Map),
        isTrue,
      );
      final json = jsonEncode(withReflection);
      expect(json.contains('"reflectionPrompt":{'), isFalse);
      expect(json.contains('"closingMessage":{'), isFalse);

      final none = YildiznameNarrativePayload.resultToMap(
        YildiznameNarrativeStructuredResult(
          contractVersion: kYildiznameResultContractVersion,
          languageCode: 'tr',
          scope: sampleResult().scope,
          summary: sampleResult().summary,
          sections: sampleResult().sections,
          reflectionPrompt: null,
          closingMessage: 'Kapanış.',
        ),
      );
      expect(none.containsKey('reflectionPrompt'), isTrue);
      expect(none['reflectionPrompt'], isNull);
      expect(none['closingMessage'], 'Kapanış.');
    });

    test(
      'save → fresh reopen preserves the strings, hash and presentation',
      () async {
        final storage = fakeLocalStorage();
        const owner = 'owner-8c2b';
        final completion = YildiznameNarrativeCompletionService(
          artifactRepo(storage, owner),
        );
        final result = sampleResult();
        final saved = await completion.complete(
          ownerId: owner,
          request: sampleRequest(),
          result: result,
          semanticFingerprint: 'sem-8c2b',
          evidenceFingerprint: 'ev-8c2b',
          createdAtUtc: DateTime.utc(2026, 9, 27),
        );

        final stored = saved.payload['result'] as Map<String, dynamic>;
        expect(stored['reflectionPrompt'], result.reflectionPrompt);
        expect(stored['closingMessage'], result.closingMessage);

        // A brand-new repository over the same storage — no cache, no provider.
        final again = await YildiznameArtifactReopen(
          artifactRepo(storage, owner),
        ).requireById(saved.id);
        YildiznameArtifactIntegrity.verify(again);
        expect(again.id, saved.id);
        expect(again.contentHash, saved.contentHash);
        expect(jsonEncode(again.payload), jsonEncode(saved.payload));
        final reopened = again.payload['result'] as Map<String, dynamic>;
        expect(reopened['reflectionPrompt'], result.reflectionPrompt);
        expect(reopened['closingMessage'], result.closingMessage);

        final p = YildiznameArtifactPresentation.of(again, chromeLocale: 'tr');
        final byRole = {for (final s in p.sections) s.role: s.body};
        expect(
          byRole[YildiznameSectionRole.reflection],
          result.reflectionPrompt,
        );
        expect(byRole[YildiznameSectionRole.closing], result.closingMessage);
        expect(p, YildiznameArtifactPresentation.of(saved, chromeLocale: 'tr'));
      },
    );

    test('a null reflection reopens with no reflection section', () async {
      final base = sampleResult();
      final result = YildiznameNarrativeStructuredResult(
        contractVersion: base.contractVersion,
        languageCode: base.languageCode,
        scope: base.scope,
        summary: base.summary,
        sections: base.sections,
        reflectionPrompt: null,
        closingMessage: base.closingMessage,
      );
      final storage = fakeLocalStorage();
      final saved =
          await YildiznameNarrativeCompletionService(
            artifactRepo(storage, 'o'),
          ).complete(
            ownerId: 'o',
            request: sampleRequest(),
            result: result,
            semanticFingerprint: 's',
            evidenceFingerprint: 'e',
            createdAtUtc: DateTime.utc(2026, 9, 27),
          );
      final p = YildiznameArtifactPresentation.of(saved, chromeLocale: 'tr');
      final roles = [for (final s in p.sections) s.role];
      expect(roles.contains(YildiznameSectionRole.reflection), isFalse);
      expect(roles.contains(YildiznameSectionRole.closing), isTrue);
      expect(
        [for (final s in p.sections) s.body].any((b) => b.contains('null')),
        isFalse,
      );
    });

    test('acceptedThemeRefs derive from summary + sections only', () {
      final payload = <String, dynamic>{
        'request': <String, dynamic>{},
        'result': {
          'summary': {
            'text': 's',
            'factRefs': <String>[],
            'themeRefs': ['theme.0'],
          },
          'sections': [
            {
              'kind': 'core_identity',
              'text': 't',
              'factRefs': <String>[],
              'themeRefs': ['theme.1'],
            },
          ],
          // A historical block-shaped value must NOT gain evidence authority.
          'reflectionPrompt': {
            'text': 'r',
            'factRefs': <String>[],
            'themeRefs': ['theme.9'],
          },
          'closingMessage': {
            'text': 'c',
            'factRefs': <String>[],
            'themeRefs': ['theme.8'],
          },
        },
      };
      expect(YildiznameNarrativePayload.acceptedThemeRefs(payload), {
        'theme.0',
        'theme.1',
      });
    });
  });

  group('historical block-shaped artifact — display-read only', () {
    Map<String, dynamic> oldPayload() => {
      'request': <String, dynamic>{},
      'result': {
        'contractVersion': 1,
        'languageCode': 'tr',
        'scope': 'reduced',
        'summary': {
          'text': 'Eski özet metni.',
          'factRefs': <String>[],
          'themeRefs': <String>[],
        },
        'sections': [
          {
            'kind': 'core_identity',
            'text': 'Eski bölüm.',
            'factRefs': <String>[],
            'themeRefs': <String>[],
          },
        ],
        'reflectionPrompt': {
          'text': 'Eski yansıma sorusu?',
          'factRefs': ['placement.sun'],
          'themeRefs': ['theme.5'],
        },
        'closingMessage': {
          'text': 'Eski kapanış.',
          'factRefs': <String>[],
          'themeRefs': <String>[],
        },
      },
    };

    test('old text still reopens; nothing is rewritten or re-hashed', () {
      final payload = oldPayload();
      final before = jsonEncode(payload);
      final artifact = yildiznameFixtureRawNarrativeArtifact(
        payload: payload,
        scope: 'reduced',
        fidelity: 'reducedNatal',
      );
      final hash = artifact.contentHash;
      final p = YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
      final byRole = {for (final s in p.sections) s.role: s.body};
      expect(byRole[YildiznameSectionRole.reflection], 'Eski yansıma sorusu?');
      expect(byRole[YildiznameSectionRole.closing], 'Eski kapanış.');
      // No migration: payload and hash are byte-identical after projection.
      expect(jsonEncode(artifact.payload), before);
      expect(artifact.contentHash, hash);
    });

    test('its old refs carry no authority (theme refs ignored)', () {
      expect(
        YildiznameNarrativePayload.acceptedThemeRefs(oldPayload()),
        isEmpty,
      );
    });

    test('a block without text or a non-string is simply not shown', () {
      final payload = oldPayload();
      (payload['result'] as Map)['reflectionPrompt'] = {'factRefs': <String>[]};
      (payload['result'] as Map)['closingMessage'] = 42;
      final p = YildiznameArtifactPresentation.of(
        yildiznameFixtureRawNarrativeArtifact(payload: payload),
        chromeLocale: 'tr',
      );
      final roles = [for (final s in p.sections) s.role];
      expect(roles.contains(YildiznameSectionRole.reflection), isFalse);
      expect(roles.contains(YildiznameSectionRole.closing), isFalse);
    });
  });
}
