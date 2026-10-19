/// Late fortune rows stay with the account that started them.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/owner_history_scope.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late int epoch;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    epoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    await storage.setString(UserLocalDataIsolation.ownerKey, 'account-a');
  });

  tearDown(() {
    UserLocalDataIsolation.accountSwitchEpoch.value = epoch;
  });

  CoffeeReading coffee(String id) => CoffeeReading(
        id: id,
        createdAt: DateTime.utc(2026, 10, 19),
        overall: 'A cup',
        love: 'A',
        career: 'A',
        money: 'A',
        nearFuture: 'A',
        takeaway: 'A',
      );

  test('a late coffee row does not land on the next account', () async {
    final store = CoffeeReadingStore(storage);
    final stamp = (
      ownerId: store.currentOwnerId,
      epoch: UserLocalDataIsolation.accountSwitchEpoch.value,
    );
    await storage.setString(UserLocalDataIsolation.ownerKey, 'account-b');
    UserLocalDataIsolation.accountSwitchEpoch.value = stamp.epoch + 1;

    await expectLater(
      OwnerHistoryScope.commitBound(
        ownerId: stamp.ownerId,
        epoch: stamp.epoch,
        save: () => store.save(coffee('cup-a')),
      ),
      throwsA(isA<OwnerHistoryRejected>()),
    );
    expect(store.all(), isEmpty);
  });

  test('the same coffee operation replaces its row', () async {
    final store = CoffeeReadingStore(storage);
    final stamp = (
      ownerId: store.currentOwnerId,
      epoch: UserLocalDataIsolation.accountSwitchEpoch.value,
    );
    await OwnerHistoryScope.commitBound(
      ownerId: stamp.ownerId,
      epoch: stamp.epoch,
      save: () => store.save(coffee('cup-a')),
    );
    await OwnerHistoryScope.commitBound(
      ownerId: stamp.ownerId,
      epoch: stamp.epoch,
      save: () => store.save(coffee('cup-a')),
    );
    expect(store.all(), hasLength(1));
    expect(store.byId('cup-a')?.overall, 'A cup');
  });

  test('a late tarot journal row does not land on the next account', () async {
    final history = MockHistoryRepository(storage);
    final stamp = (
      ownerId: 'account-a',
      epoch: UserLocalDataIsolation.accountSwitchEpoch.value,
    );
    await storage.setString(UserLocalDataIsolation.ownerKey, 'account-b');
    UserLocalDataIsolation.accountSwitchEpoch.value = stamp.epoch + 1;
    final reading = ReadingModel(
      id: 'session-a',
      cardId: 17,
      cardName: 'The Star',
      cardImageAsset: 'star',
      spreadType: 'single',
      aiSummary: 'A reading',
      createdAt: DateTime.utc(2026, 10, 19),
      userId: 'account-a',
    );

    await expectLater(
      OwnerHistoryScope.bind(
        ownerId: stamp.ownerId,
        epoch: stamp.epoch,
        body: () => history.saveReading(reading),
      ),
      throwsA(isA<OwnerHistoryRejected>()),
    );
    expect(await history.getReadings(), isEmpty);
  });

  test('the same tarot id does not create a second journal row', () async {
    final history = MockHistoryRepository(storage);
    ReadingModel row(String summary) => ReadingModel(
          id: 'session-a',
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'star',
          spreadType: 'single',
          aiSummary: summary,
          createdAt: DateTime.utc(2026, 10, 19),
          userId: 'account-a',
        );
    await history.saveReading(row('First'));
    await history.saveReading(row('First'));
    final saved = await history.getReadings();
    expect(saved, hasLength(1));
    expect(saved.single.aiSummary, 'First');
  });
}
