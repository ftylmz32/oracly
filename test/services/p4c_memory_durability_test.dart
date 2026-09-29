/// P4C — a memory edit is one durable write.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/models/memory_item.dart';
import 'package:oracly_new/screens/memory/memory_screen.dart';
import 'package:oracly_new/services/memory_service.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';

import '../test_helpers/provider_scope_harness.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  MemoryItem row(String content) => MemoryItem(
    category: 'goal',
    content: content,
    importance: 'high',
    createdAt: DateTime(2026, 1, 2),
  );

  test('a failed replacement keeps the original memory', () async {
    final storage = _FlakyStorage();
    final service = MemoryService(storage);
    await service.addAdvancedMemory(row('Keep this'));
    storage.failNext = true;

    final saved = await service.updateMemory(
      row('Keep this'),
      row('Replacement'),
    );

    expect(saved, isFalse);
    final memories = await service.getAdvancedMemories();
    expect(memories, hasLength(1));
    expect(memories.single.content, 'Keep this');
    expect(memories.single.category, 'goal');
    expect(memories.single.importance, 'high');
    expect(memories.single.createdAt, DateTime(2026, 1, 2));
  });

  test('a duplicate edit does not delete the original', () async {
    final service = MemoryService(LocalStorage.ephemeral());
    await service.addAdvancedMemory(row('Alpha'));
    await service.addAdvancedMemory(row('Beta'));

    final saved = await service.updateMemory(row('Alpha'), row('beta'));

    expect(saved, isFalse);
    final memories = await service.getAdvancedMemories();
    expect(memories.map((item) => item.content), ['Alpha', 'Beta']);
  });

  test('a successful edit is one row and keeps metadata', () async {
    final service = MemoryService(LocalStorage.ephemeral());
    await service.addAdvancedMemory(row('Alpha'));

    final saved = await service.updateMemory(
      row('Alpha'),
      row('Alpha revised'),
    );

    expect(saved, isTrue);
    final memories = await service.getAdvancedMemories();
    expect(memories, hasLength(1));
    expect(memories.single.content, 'Alpha revised');
    expect(memories.single.createdAt, DateTime(2026, 1, 2));
    expect(memories.single.importance, 'high');
  });

  test('a failed delete leaves the memory stored', () async {
    final storage = _FlakyStorage();
    final service = MemoryService(storage);
    await service.addAdvancedMemory(row('Stay'));
    storage.failNext = true;

    expect(await service.removeMemory('Stay'), isFalse);
    expect((await service.getAdvancedMemories()).single.content, 'Stay');
  });

  testWidgets('the screen keeps the original note when the edit cannot save', (
    tester,
  ) async {
    final storage = _FlakyStorage();
    final service = MemoryService(storage);
    await service.addAdvancedMemory(row('Visible original'));
    storage.failNext = true;

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [memoryServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: MemoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Should not stick');
    await tester.tap(find.byType(OraclyGoldButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Visible original'), findsOneWidget);
    expect(find.text('Should not stick'), findsNothing);
    expect(find.text(ResilienceCopy.genericLoadFailed), findsOneWidget);
    expect(
      (await service.getAdvancedMemories()).single.content,
      'Visible original',
    );
  });

  testWidgets('a long memory fits a short phone', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    final storage = LocalStorage.ephemeral();
    final service = MemoryService(storage);
    await service.addAdvancedMemory(
      row('A long personal note that must wrap instead of overflowing the row'),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.4),
        ),
        child: buildProviderScopeHarness(
          storage: storage,
          overrides: [memoryServiceProvider.overrideWithValue(service)],
          child: const MaterialApp(home: MemoryScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('A long personal note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FlakyStorage extends LocalStorage {
  _FlakyStorage() : super.ephemeral();

  bool failNext = false;

  @override
  Future<bool> setStringList(String key, List<String> values) async {
    if (failNext && key == 'user_memories') {
      failNext = false;
      return false;
    }
    return super.setStringList(key, values);
  }
}
