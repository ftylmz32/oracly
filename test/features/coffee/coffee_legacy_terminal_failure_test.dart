/// Slice 4D — client side of the legacy single-photo Coffee terminal
/// contract. The backend now settles an insufficient / malformed legacy
/// Coffee outcome as a typed terminal FAILURE (never a ready reading). The
/// existing legacy client recovering that operation (fresh controller =
/// app relaunch) must show the existing error state — no success result,
/// no history entry, no raw backend diagnostics, no AI call — every time.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

class _NoAnalysis implements CoffeeAnalysisPort {
  int calls = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    calls++;
    throw StateError('server-owned: the client never analyzes');
  }
}

class _NoImages implements CoffeeImageInputPort {
  @override
  bool get cameraAvailable => false;
  @override
  bool get galleryAvailable => false;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a server-failed legacy Coffee operation recovers into the existing error state, every relaunch',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = CoffeeReadingStore(LocalStorage(await SharedPreferences.getInstance()));
    final backend = FakeReadingOperationBackend();
    final analysis = _NoAnalysis();

    // A legacy unslotted Coffee operation the server settled as failed.
    final created = await backend.send('POST', '/v1/reading-operations', {
      'readingType': 'coffee',
      'sourceRequestId': 'coffee-legacy-4d-1',
      'language': 'tr',
    });
    final operationId = (created!.json!['data'] as Map)['operationId'] as String;
    await backend.send('POST', '/v1/reading-operations/$operationId/fail', const {});

    for (var relaunch = 0; relaunch < 2; relaunch++) {
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(store: store, analysis: analysis),
        images: _NoImages(),
        live: fakeImmediateReadingFeatureRunner(
          backend: backend,
          serverOwnedCompletion: true,
        ),
      );
      await controller.recoverActive();
      expect(controller.phase, CoffeePhase.error, reason: 'relaunch $relaunch');
      expect(controller.reading, isNull);
      final message = controller.errorMessage ?? '';
      expect(message, isNotEmpty);
      for (final raw in [
        'insufficient_semantic_signal',
        'no_safe_semantic_facets',
        'insufficient_semantic_capacity',
        'invalid',
      ]) {
        expect(message.contains(raw), isFalse, reason: raw);
      }
      controller.dispose();
    }
    expect(store.all(), isEmpty); // never a history entry
    expect(analysis.calls, 0);
    expect(backend.operationCount, 1); // no automatic new operation
    expect(backend.resultFetchCalls, 0);
  });
}
