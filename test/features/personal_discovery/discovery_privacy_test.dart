/// Phase 11 — no secrets, no uid, no raw image by default.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('palm and oracle payloads never carry uid, token, or api key', () {
    final palm = OpenAiServiceRequests.palm(
      model: 'gpt-test',
      imageBytes: List<int>.filled(8, 2),
      mimeType: 'image/jpeg',
      hand: 'left',
    );
    final oracle = OpenAiServiceRequests.oracle(
      model: 'gpt-test',
      context: const AstrologyAiContext(
        signLabel: 'Koç',
        daily: 'Sakin ilerle.',
      ),
      userMessage: 'Ne hissediyorum?',
      priorUser: const [],
      observedThemes: const ['sınırlar'],
    );
    final chat = OpenAiServiceRequests.chat(
      model: 'gpt-test',
      userMessage: 'Merhaba',
      priorUser: const [],
      styleHint: 'Nazik ol.',
    );
    for (final request in [palm, oracle, chat]) {
      final blob = request.toJson().toString();
      expect(request.payload.containsKey('uid'), isFalse);
      expect(request.payload.containsKey('userId'), isFalse);
      expect(request.payload.containsKey('firebaseUid'), isFalse);
      expect(blob, isNot(contains('sk-')));
      expect(blob, isNot(contains('Bearer')));
      expect(blob, isNot(contains('Authorization')));
    }
    expect(palm.operation, AiOperation.palmAnalysis);
  });

  test('palm store keeps takeaway and app-owned imagePath', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PalmReadingStore(await LocalStorage.open());
    await store.save(
      PalmReading(
        id: 'p-keep',
        createdAt: DateTime(2026, 8, 13),
        hand: PalmHand.left,
        overall: 'Açık bir avuç.',
        takeaway: 'En net işaret yakınlık.',
        imagePath: '/tmp/kept.jpg',
      ),
    );
    final saved = store.all().single;
    expect(saved.imagePath, '/tmp/kept.jpg');
    expect(saved.takeaway, 'En net işaret yakınlık.');
  });
}
