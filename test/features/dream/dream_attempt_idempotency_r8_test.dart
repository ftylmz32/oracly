/// R8 — Dream MODEL B: same narrative reuses attempt id; wipe clears it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_binder.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late DreamAttemptStore attempts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    attempts = DreamAttemptStore(storage);
  });

  test('same narrative reuses stable attempt id across retries', () async {
    final first = await attempts.resolveId('  Flying over water  ');
    final second = await attempts.resolveId('flying over water');
    expect(second, first);
    expect(first.startsWith('or-dream-'), isTrue);
  });

  test('changed narrative creates a new attempt id', () async {
    final first = await attempts.resolveId('old dream');
    final second = await attempts.resolveId('new dream');
    expect(second, isNot(first));
  });

  test('clear forces a fresh attempt on next resolve', () async {
    final first = await attempts.resolveId('same narrative');
    await attempts.clear();
    final second = await attempts.resolveId('same narrative');
    expect(second, isNot(first));
  });

  test('binder key matches PaidAiOperationId.fromExisting for attempt', () async {
    final id = await attempts.resolveId('binder check');
    final key = PaidAiOperationId.fromExisting('dream', id);
    expect(key, id);
    var observed = '';
    await PaidAiOperationBinder.runWithKey(key, () async {
      observed = PaidAiOperationBinder.idempotencyKey ?? '';
    });
    expect(observed, id);
  });

  test('account wipe removes dream attempt recovery key', () async {
    await attempts.resolveId('wipe me');
    expect(storage.getString(DreamAttemptStore.key), isNotNull);
    await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(storage.getString(DreamAttemptStore.key), isNull);
  });
}
