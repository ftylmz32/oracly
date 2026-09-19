/// MemoryService — canonical LocalStorage boundary, malformed-row
/// tolerance, and account-isolation coverage for the legacy "OR memory"
/// storage path (user_name / user_memories).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/models/memory_item.dart';
import 'package:oracly_new/screens/memory/memory_screen.dart';
import 'package:oracly_new/services/memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('canonical storage boundary', () {
    test('reads and writes through the injected LocalStorage, not a second '
        'independent SharedPreferences instance', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = MemoryService(storage: storage);

      await service.saveUserName('Ada');
      await service.addAdvancedMemory(
        MemoryItem(
          category: 'goal',
          content: 'Learn Turkish',
          importance: 'high',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      // The SAME storage instance sees exactly what the service wrote —
      // proving there is no second, independent SharedPreferences path.
      expect(storage.getString('user_name'), 'Ada');
      expect(storage.getStringList('user_memories')?.length, 1);
      expect(await service.getUserName(), 'Ada');
    });

    test('memoryServiceProvider wires MemoryService to the same '
        'localStorageProvider instance the rest of the app uses', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final service = container.read(memoryServiceProvider);
      await service.saveUserName('Injected');

      expect(storage.getString('user_name'), 'Injected');
    });
  });

  group('malformed legacy rows never crash', () {
    test('a corrupt JSON row is preserved as raw text instead of being '
        'discarded or throwing', () async {
      SharedPreferences.setMockInitialValues({
        'user_memories': [
          '{"category":"goal","content":"Valid row","importance":"high","createdAt":"2026-01-01T00:00:00.000"}',
          'not even close to json {{{',
        ],
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = MemoryService(storage: storage);

      final memories = await service.getAdvancedMemories();

      expect(memories, hasLength(2));
      expect(memories[0].content, 'Valid row');
      // The malformed row survives as its own raw content rather than
      // crashing the read or silently vanishing.
      expect(memories[1].content, 'not even close to json {{{');
    });
  });

  group('edit / delete propagation', () {
    test('removeMemory then addAdvancedMemory (the MemoryScreen edit path) '
        'leaves exactly the updated content, no duplicate', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = MemoryService(storage: storage);
      final original = MemoryItem(
        category: 'goal',
        content: 'Old value',
        importance: 'normal',
        createdAt: DateTime(2026, 1, 1),
      );
      await service.addAdvancedMemory(original);

      await service.removeMemory(original.content);
      await service.addAdvancedMemory(
        MemoryItem(
          category: original.category,
          content: 'New value',
          importance: original.importance,
          createdAt: original.createdAt,
        ),
      );

      final memories = await service.getAdvancedMemories();
      expect(memories, hasLength(1));
      expect(memories.single.content, 'New value');
    });

    test('delete removes the memory permanently', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = MemoryService(storage: storage);
      await service.addAdvancedMemory(
        MemoryItem(
          category: 'goal',
          content: 'To be deleted',
          importance: 'normal',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await service.removeMemory('To be deleted');

      expect(await service.getAdvancedMemories(), isEmpty);
    });
  });

  group('account isolation', () {
    test('UserLocalDataWipe clears both user_memories AND user_name — '
        'regression: user_name was previously missing from the wipe list, '
        'letting a new account on the same device inherit the prior '
        "account's saved display name", () async {
      SharedPreferences.setMockInitialValues({
        'user_name': 'Owner A',
        'user_memories': [
          '{"category":"goal","content":"Owner A secret","importance":"high","createdAt":"2026-01-01T00:00:00.000"}',
        ],
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = MemoryService(storage: storage);
      expect(await service.getUserName(), 'Owner A');
      expect(await service.getAdvancedMemories(), isNotEmpty);

      await UserLocalDataWipe.run(storage, secureStorage: InMemorySecureStorage());

      expect(await service.getUserName(), isNull);
      expect(await service.getAdvancedMemories(), isEmpty);
    });

    test('clearMemory() also clears the saved display name', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = MemoryService(storage: storage);
      await service.saveUserName('Someone');
      await service.addAdvancedMemory(
        MemoryItem(
          category: 'goal',
          content: 'A memory',
          importance: 'normal',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await service.clearMemory();

      expect(await service.getUserName(), isNull);
      expect(await service.getAdvancedMemories(), isEmpty);
    });
  });

  group('MemoryScreen uses the canonical injected service', () {
    testWidgets(
      'a memory already present in the shared LocalStorage is visible on '
      'screen without the screen ever constructing its own MemoryService',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'user_memories': [
            '{"category":"goal","content":"Seeded via shared storage","importance":"normal","createdAt":"2026-01-01T00:00:00.000"}',
          ],
        });
        final storage = LocalStorage(await SharedPreferences.getInstance());

        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            child: const MaterialApp(home: MemoryScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.textContaining('Seeded via shared storage'), findsOneWidget);
      },
    );
  });
}
