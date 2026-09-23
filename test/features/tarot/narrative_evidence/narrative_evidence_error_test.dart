import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_error.dart';

void main() {
  group('NarrativeEvidenceErrorCode', () {
    test('exact closed set', () {
      expect(NarrativeEvidenceErrorCode.values.map((e) => e.name).toList(), [
        'unknownCanonicalCardId',
        'profileMissing',
        'duplicatePositionKey',
        'cardCountMismatch',
        'unknownPositionKey',
        'invalidOrientation',
        'spreadMismatch',
        'invalidOntologyId',
        'duplicateEvidenceId',
        'duplicateCardId',
        'ritualCardMismatch',
      ]);
    });

    test('exception carries code + safe message', () {
      const err = NarrativeEvidenceException(
        NarrativeEvidenceErrorCode.profileMissing,
        message: 'profile not found for id',
      );
      expect(err.code, NarrativeEvidenceErrorCode.profileMissing);
      expect(err.message, isNot(contains('Should I')));
      expect(err.toString(), contains('profileMissing'));
    });
  });

  group('Evidence production forbidden references', () {
    test('no forbidden imports/refs in evidence/*.dart', () {
      final dir = Directory('lib/features/tarot/narrative/evidence');
      expect(dir.existsSync(), isTrue);
      final forbidden = [
        RegExp(r'package:http/'),
        RegExp(r'package:dio/'),
        RegExp(r'firebase', caseSensitive: false),
        RegExp(r'SharedPreferences'),
        RegExp(r'HistoryService'),
        RegExp(r'JourneyPersonalizationHints'),
        RegExp(r'TarotInterpretationService'),
        RegExp(r'InterpretationEngine'),
        RegExp(r'AiInterpretationExecutor'),
      ];
      for (final file in dir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final src = file.readAsStringSync();
        for (final pattern in forbidden) {
          expect(
            pattern.hasMatch(src),
            isFalse,
            reason: '${file.path} matched ${pattern.pattern}',
          );
        }
      }
    });
  });
}
