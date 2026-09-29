/// P3C — coffee loading identity and locale-aware history dates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_loading_view.dart';
import 'package:oracly_new/features/reading_operation/copy/reading_live_copy.dart';
import 'package:oracly_new/features/reading_operation/presentation/reading_wait_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('coffee wait shows the cup copy, not the generic headline', (
    tester,
  ) async {
    const message = 'Looking a little closer at the cup...';
    const subtitle = 'Looking at your real cup photo — no hurry.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoffeeLoadingView(message: message, subtitle: subtitle),
        ),
      ),
    );
    expect(find.text(message), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
    expect(find.text(ReadingLiveCopy.headline), findsNothing);
  });

  testWidgets('shared wait keeps the generic headline when no feature copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ReadingWaitScreen(liveState: null))),
    );
    expect(find.text(ReadingLiveCopy.headline), findsOneWidget);
    expect(find.text(ReadingLiveCopy.subtitle), findsOneWidget);
  });

  test('history dates follow the bound locale, not a dotted stamp', () {
    final day = DateTime(2026, 9, 29);
    OraclyL10n.bind('tr');
    expect(OraclyFormat.dateCompact(day), '29 Eyl 2026');
    OraclyL10n.bind('en');
    expect(OraclyFormat.dateCompact(day), 'Sep 29, 2026');
    OraclyL10n.bind('ru');
    expect(OraclyFormat.dateCompact(day), '29 сен 2026');
    expect(OraclyFormat.dateCompact(day), isNot('29.9.2026'));
  });

  test('saved cups stay newest first', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final store = CoffeeReadingStore(storage);
    await store.save(_reading('older', DateTime(2026, 1, 2)));
    await store.save(_reading('newer', DateTime(2026, 9, 29)));
    final items = store.all();
    expect(items.map((e) => e.id).toList(), ['newer', 'older']);
  });
}

CoffeeReading _reading(String id, DateTime createdAt) {
  return CoffeeReading(
    id: id,
    createdAt: createdAt,
    overall: 'A quiet cup.',
    love: '',
    career: '',
    money: '',
    nearFuture: '',
    takeaway: 'Leave it here.',
  );
}
