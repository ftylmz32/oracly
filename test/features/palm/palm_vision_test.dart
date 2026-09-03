/// Phase 6 — palm vision parse + fail-closed. Never invents medical fate.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_results.dart';
import 'package:oracly_new/features/ai/production/openai/palm_vision_parser.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/services/unavailable_palm_analysis.dart';

void main() {
  test('parser reads symbolic palm fields from a real map', () {
    final parsed = PalmVisionParser.fromMap({
      'gorselTespit': 'Açık avuç; ana çizgiler net, kalp çizgisi hafif.',
      'genelYapi': 'Avuç açık ve sakin bir ritim taşıyor.',
      'yasamCizgisi': 'Yaşam çizgisi net; tempo yavaş okunuyor.',
      'zihinCizgisi': 'Zihin çizgisi karar anlarını hatırlatıyor.',
      'kalpCizgisi': 'Kalp çizgisi yakınlık temasını taşıyor.',
      'kaderYon': 'Yön çizgisi bir sapma ihtimalini ima ediyor.',
      'semboller': ['yıldız'],
      'temalar': ['introspection', 'relationship focus'],
      'sonuc': 'Bu okuma sembolik bir yansımadır.',
    });
    expect(parsed, isNotNull);
    expect(parsed!['overall'], contains('sakin'));
    expect(parsed['themes'], contains('introspection'));
  });

  test('parser rejects medical or fatal certainty copy', () {
    expect(
      PalmVisionParser.fromMap({
        'overall': 'Ömrün şu kadar sürecek ve hastalığa sahipsin.',
        'takeaway': 'Kesin olacak.',
      }),
      isNull,
    );
  });

  test('results wrapper fail-closes on empty or forbidden maps', () {
    final empty = OpenAiServiceResults.palm(AiOutcome.success(const {}));
    empty.when(
      success: (_) => fail('empty map must not succeed'),
      error: (e) => expect(e.kind, AiFailureKind.invalidResponse),
    );
    final banned = OpenAiServiceResults.palm(
      AiOutcome.success(const {
        'overall': 'Kesin olacak bir hastalık var.',
      }),
    );
    banned.when(
      success: (_) => fail('forbidden copy must not succeed'),
      error: (e) => expect(e.kind, AiFailureKind.invalidResponse),
    );
  });

  test('proxy request is palm_analysis and never carries a uid', () {
    final request = OpenAiServiceRequests.palm(
      model: 'gpt-test',
      imageBytes: List<int>.filled(16, 1),
      mimeType: 'image/jpeg',
      hand: 'right',
    );
    expect(request.operation, AiOperation.palmAnalysis);
    expect(request.operation.wireName, 'palm_analysis');
    expect(request.payload.containsKey('userId'), isFalse);
    expect(request.payload.containsKey('uid'), isFalse);
    expect(request.payload['hand'], 'right');
  });

  test('unconfigured and unavailable ports stay fail-closed', () async {
    const ai = UnconfiguredOraclyAiService();
    final outcome = await ai.analyzePalm(
      imageBytes: const [1, 2, 3],
      mimeType: 'image/jpeg',
      hand: 'left',
    );
    outcome.when(
      success: (_) => fail('unconfigured must not invent a palm reading'),
      error: (e) => expect(e.kind, AiFailureKind.imageAnalysisUnavailable),
    );
    expect(const UnavailablePalmAnalysis().isAvailable, isFalse);
    expect(PalmCopy.disclaimer.toLowerCase(), contains('sembolik'));
    expect(PalmHand.right.label, 'Sağ el');
  });
}
