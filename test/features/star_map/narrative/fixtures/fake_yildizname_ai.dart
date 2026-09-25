/// Scripted fake AI — zero real provider calls.
library;

import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/oracly_narrative_yildizname_ai_service.dart';

typedef NarrativeScript =
    Future<AiOutcome<Map<String, dynamic>>> Function({
  required Map<String, dynamic> payload,
  required String fingerprint,
  required int attempt,
});

class FakeYildiznameAi implements OraclyNarrativeYildiznameAiService {
  FakeYildiznameAi(this._script);

  final NarrativeScript _script;
  final calls = <Map<String, Object?>>[];

  @override
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeYildiznameReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
    int attempt = 1,
  }) async {
    calls.add({
      'fingerprint': fingerprint,
      'attempt': attempt,
      'payload': payload,
    });
    return _script(
      payload: payload,
      fingerprint: fingerprint,
      attempt: attempt,
    );
  }
}

AiOutcome<Map<String, dynamic>> okMap(Map<String, dynamic> m) =>
    AiOutcome.success(m);

AiOutcome<Map<String, dynamic>> failProvider() =>
    AiOutcome.failure(AiFailure.invalidResponse());
