/// Coffee Fortune vision activation â€” proxy path, parse, fail-closed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/coffee_vision_parser.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_results.dart';
import 'package:oracly_new/features/ai/production/transport/ai_error_mapper.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coffee request is coffee_analysis with image payload, no secrets', () {
    final request = OpenAiServiceRequests.coffee(
      model: 'gpt-test',
      imageBytes: List<int>.filled(32, 7),
      mimeType: 'image/jpeg',
    );
    expect(request.operation, AiOperation.coffeeAnalysis);
    expect(request.operation.wireName, 'coffee_analysis');
    expect(request.payload['mimeType'], 'image/jpeg');
    expect(request.payload['byteLength'], 32);
    expect(request.payload['imageBase64'], isA<String>());
    expect(request.payload.containsKey('uid'), isFalse);
    expect(request.payload.containsKey('userId'), isFalse);
    expect(request.payload.containsKey('prompt'), isFalse);
    final blob = request.toJson().toString();
    expect(blob, isNot(contains('sk-')));
    expect(blob, isNot(contains('Bearer')));
    expect(blob, isNot(contains('Authorization')));
  });

  test('auth failure maps to typed unauthorized error', () {
    expect(
      AiErrorMapper.fromStatus(401).kind,
      AiFailureKind.unauthorized,
    );
  });

  test('provider success parses structured coffee fields', () {
    final outcome = OpenAiServiceResults.coffee(
      AiOutcome.success(const {
        'visualObservation': 'FincanÄ±n dibinde ince bir yol izi gÃ¶rÃ¼nÃ¼yor.',
        'overall': 'Genel enerji sakin ve Ã¶lÃ§Ã¼lÃ¼ bir geÃ§iÅŸ taÅŸÄ±yor.',
        'love': 'YakÄ±nlÄ±k temasÄ± yumuÅŸak bir aÃ§Ä±klÄ±k istiyor.',
        'career': 'Ä°ÅŸ alanÄ±nda tek bir adÄ±mÄ± tamamlamak gÃ¼Ã§ verir.',
        'money': 'Maddi tempo acele etmeden ilerliyor.',
        'nearFuture': 'YakÄ±n dÃ¶nemde kÄ±sa bir durak faydalÄ± olabilir.',
        'takeaway': 'BugÃ¼n bir iÅŸi bitirmeden yenisini aÃ§ma.',
        'symbols': [
          {'name': 'yol', 'meaning': 'yÃ¶n', 'note': 'sakin ilerleme'},
        ],
      }),
    );
    late final analysis = outcome.when(
      success: (value) => value,
      error: (_) => fail('valid map must succeed'),
    );
    expect(analysis.overall, contains('sakin'));
    expect(analysis.love, contains('YakÄ±nlÄ±k'));
    expect(analysis.career, contains('Ä°ÅŸ'));
    expect(analysis.money, contains('Maddi'));
    expect(analysis.nearFuture, contains('YakÄ±n'));
    expect(analysis.takeaway, contains('bitirmeden'));
    expect(analysis.symbols.single.name, 'yol');
  });

  test('provider empty or invalid response fail-closes', () {
    OpenAiServiceResults.coffee(AiOutcome.success(const {})).when(
      success: (_) => fail('empty must not succeed'),
      error: (e) => expect(e.kind, AiFailureKind.invalidResponse),
    );
    expect(CoffeeVisionParser.fromMap(const {}), isNull);
    expect(
      CoffeeVisionParser.fromMap(const {'love': 'sadece ask alani'}),
      isNull,
    );
  });

  test('production proxy config never selects DirectOpenAi for coffee', () {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: 'https://api.oracly.app/v1/ai/complete',
      visionEnabled: true,
    );
    final transport = AiTransportSelection.create(config);
    expect(transport, isA<ProxyAiTransport>());
    expect(transport, isNot(isA<DirectOpenAiTransport>()));
    expect(config.visionAvailable, isTrue);
  });

  test('result copy exposes required coffee sections', () {
    expect(CoffeeCopy.overallTitle, 'FİNCANIN SANA ANLATTIĞI');
    expect(CoffeeCopy.loveTitle, 'AŞK');
    expect(CoffeeCopy.careerTitle, 'İŞ');
    expect(CoffeeCopy.nearFutureTitle, 'HABER');
    expect(CoffeeCopy.cautionTitle, 'DİKKAT');
  });

  testWidgets('no-photo submit stays blocked when vision is unavailable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          coffeeAnalysisProvider
              .overrideWithValue(const UnavailableCoffeeAnalysis()),
        ],
        child: const MaterialApp(home: CoffeeReferenceScreen()),
      ),
    );
    await tester.pump();
    ProviderScope.containerOf(
      tester.element(find.byType(CoffeeReferenceScreen)),
    ).read(coffeeReadingControllerProvider).startCapture();
    await tester.pump();
    // Without a photo the analyze CTA stays hidden.
    expect(find.text(CoffeeCopy.analyzeCta), findsNothing);
  });
}

