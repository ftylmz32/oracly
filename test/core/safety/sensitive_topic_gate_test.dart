import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/safety/sensitive_topic_detector.dart';
import 'package:oracly_new/core/safety/sensitive_topic_gate.dart';
import 'package:oracly_new/core/safety/sensitive_topic_kind.dart';
import 'package:oracly_new/core/safety/sensitive_topic_output_checks.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  group('SensitiveTopicDetector', () {
    test('health question in fortune context', () {
      expect(
        SensitiveTopicDetector.detect('Bu fal hastalığımı gösteriyor mu?'),
        SensitiveTopicKind.health,
      );
    });

    test('crisis self-harm', () {
      expect(
        SensitiveTopicDetector.detect('Kendimi öldürmek istiyorum'),
        SensitiveTopicKind.crisis,
      );
    });

    test('financial guarantee ask', () {
      expect(
        SensitiveTopicDetector.detect('Tarot yatırım garanti kazanç söyler mi?'),
        SensitiveTopicKind.financial,
      );
    });

    test('legal fortune ask', () {
      expect(
        SensitiveTopicDetector.detect('Fal dava kazanır mıyım der mi?'),
        SensitiveTopicKind.legal,
      );
    });

    test('relationship certainty ask', () {
      expect(
        SensitiveTopicDetector.detect('Tarot kesin beni seviyor mu?'),
        SensitiveTopicKind.relationship,
      );
    });

    test('fear prediction ask', () {
      expect(
        SensitiveTopicDetector.detect('Ne zaman öleceğim fal söyler mi?'),
        SensitiveTopicKind.fear,
      );
    });
  });

  group('SensitiveTopicGate', () {
    test('health response is localized and non-diagnostic', () {
      final reply = SensitiveTopicGate.maybeRespond(
        'Bu fal hastalığımı gösteriyor mu?',
      );
      expect(reply, isNotNull);
      expect(reply!.toLowerCase(), contains('güvenilir'));
      expect(reply.toLowerCase(), contains('profesyonel'));
      expect(reply.toLowerCase(), isNot(contains('teşhis')));
    });

    test('crisis bypasses fortune voice', () {
      final reply = SensitiveTopicGate.maybeRespond('Intihar etmeyi düşünüyorum');
      expect(reply, isNotNull);
      expect(reply!.toLowerCase(), contains('182'));
      expect(reply.toLowerCase(), isNot(contains('kart')));
    });
  });

  group('SensitiveTopicOutputChecks', () {
    test('blocks medical diagnosis output', () {
      expect(
        SensitiveTopicOutputChecks.claimsMedicalDiagnosis(
          'Hastalığın şu olabilir.',
        ),
        isTrue,
      );
    });

    test('blocks fear and definite love output', () {
      expect(
        SensitiveTopicOutputChecks.predictsFear('Felaket kapıda duruyor.'),
        isTrue,
      );
      expect(
        SensitiveTopicOutputChecks.claimsDefiniteLove('Kesin seni seviyor.'),
        isTrue,
      );
    });
  });
}
