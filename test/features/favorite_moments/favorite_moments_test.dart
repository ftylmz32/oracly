/// Favorite moments — save, unsave, persist, privacy gates.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/daily_message/models/daily_message.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moments_service.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('copy matches product action', () {
    expect(FavoriteMomentsCopy.title, 'Favori Anlarım');
    expect(FavoriteMomentsCopy.save, 'Bu anı kaydet');
    expect(FavoriteMomentsCopy.unsave, 'Kaydı kaldır');
  });

  test('save and remove persist across repository reads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = FavoriteMomentsService(
      LocalFavoriteMomentsRepository(storage),
    );
    final moment = FavoriteMomentFactory.companion(
      AIMessage(
        id: 'm1',
        role: AIMessageRole.assistant,
        content: 'Kariyer tarafında yavaş bir geçiş görünüyor.',
        createdAt: DateTime(2026, 8, 10),
      ),
    );
    await service.save(moment);
    expect(await service.isSaved(moment.id), isTrue);
    final loaded = await service.all();
    expect(loaded, hasLength(1));
    expect(loaded.first.quote, contains('geçiş'));
    await service.remove(moment.id);
    expect(await service.all(), isEmpty);
    expect(await service.isSaved(moment.id), isFalse);
  });

  test('duplicate save replaces without doubling list', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = LocalFavoriteMomentsRepository(storage);
    final base = FavoriteMomentFactory.daily(
      DailyMessage(text: 'İlk metin.', day: DateTime(2026, 8, 10)),
    );
    await repo.save(base);
    await repo.save(
      FavoriteMoment(
        id: base.id,
        source: base.source,
        sourceRef: base.sourceRef,
        savedAt: DateTime(2026, 8, 11),
        occurredAt: base.occurredAt,
        quote: 'Güncellenmiş alıntı.',
      ),
    );
    final items = await repo.getAll();
    expect(items, hasLength(1));
    expect(items.first.quote, 'Güncellenmiş alıntı.');
  });

  test('factory builds stable ids per source', () {
    final coffee = FavoriteMomentFactory.coffee(
      CoffeeReading(
        id: 'c1',
        createdAt: DateTime(2026, 8, 10),
        overall: 'Sakin bir fincan.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'Bir adım yeter.',
      ),
    );
    expect(coffee.id, 'coffee:c1');
    expect(coffee.source, FavoriteMomentSource.coffee);

    final palm = FavoriteMomentFactory.palm(
      PalmReading(
        id: 'p1',
        createdAt: DateTime(2026, 8, 10),
        hand: PalmHand.right,
        overall: 'Avuç içinde sakin bir çizgi.',
        themes: const ['Denge'],
      ),
    );
    expect(palm.id, 'palm:p1');
    expect(palm.source, FavoriteMomentSource.palm);

    final daily = FavoriteMomentFactory.daily(
      DailyMessage(text: 'Bugün nefes al.', day: DateTime(2026, 8, 10)),
    );
    expect(daily.id, 'dailyMessage:2026-08-10');
  });

  test('json round trip keeps safe quote only', () {
    final original = FavoriteMomentFactory.dream(
      id: 'd1',
      at: DateTime(2026, 8, 10),
      narrative: 'Gizli rüya metni',
      analysis: 'Yansıma cümlesi burada.',
    );
    final decoded = FavoriteMoment.fromJson(original.toJson());
    expect(decoded.quote, original.quote);
    expect(decoded.sourceRef, 'd1');
    expect(decoded.quote, isNot(contains('Gizli rüya metni')));
  });
}
