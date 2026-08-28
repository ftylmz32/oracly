/// P0-08 — one corrupt history row must not crash Reading History.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

ReadingModel _reading({
  required String id,
  required String name,
  required DateTime createdAt,
}) {
  return ReadingModel(
    id: id,
    cardId: 0,
    cardName: name,
    cardImageAsset: 'star.png',
    spreadType: 'Tek Kart',
    aiSummary: 'Yorum $id',
    createdAt: createdAt,
  );
}

Future<LocalStorage> _seedMixedHistory() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await storage.setStringList('or_reading_history', [
    jsonEncode(
      _reading(
        id: 'valid_star',
        name: 'The Star',
        createdAt: DateTime(2026, 8, 1, 10),
      ).toJson(),
    ),
    '{not-json',
    jsonEncode(
      _reading(
        id: 'valid_moon',
        name: 'The Moon',
        createdAt: DateTime(2026, 8, 2, 10),
      ).toJson(),
    ),
    'null',
    '{"id":}',
  ]);
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // History rows format dates, so load the locale data main() loads.
  setUpAll(() => OraclyFormat.ensureInitialized());

  test('getReadings skips corrupt rows and keeps valid readings', () async {
    final storage = await _seedMixedHistory();
    final repo = MockHistoryRepository(storage);

    final loaded = await repo.getReadings();

    expect(loaded.map((r) => r.id), ['valid_moon', 'valid_star']);
    expect(loaded.map((r) => r.cardName), ['The Moon', 'The Star']);
    expect(storage.getStringList('or_reading_history'), hasLength(5));
  });

  testWidgets('Reading History screen loads despite one corrupt entry',
      (tester) async {
    final storage = await _seedMixedHistory();
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: ReadingHistoryScreen()),
      ),
    );
    // Async history + entrance; ambient background repeats so avoid pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(tester.takeException(), isNull);
    expect(find.text('Geçmiş yüklenemedi'), findsNothing);
    expect(find.text('The Moon'), findsWidgets);
    // SliverList builds lazily — scroll to older corrupt-neighbor row.
    await tester.scrollUntilVisible(
      find.text('The Star'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('The Star'), findsWidgets);
  });
}
