/// Reading feedback — metadata only, free retry, no gem spend.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/gems/services/gem_action_charge.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/reading_feedback/copy/reading_feedback_copy.dart';
import 'package:oracly_new/features/reading_feedback/data/reading_feedback_store.dart';
import 'package:oracly_new/features/reading_feedback/models/reading_feedback_category.dart';
import 'package:oracly_new/features/reading_feedback/models/reading_feedback_event.dart';
import 'package:oracly_new/features/reading_feedback/services/reading_feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('copy matches product actions', () {
    expect(ReadingFeedbackCopy.action, 'Bu yorumu beğenmedim');
    expect(ReadingFeedbackCopy.retry, 'Tekrar yorumla');
    expect(ReadingFeedbackCopy.category(ReadingFeedbackCategory.missed),
        'Yanlış anladı');
    expect(ReadingFeedbackCopy.category(ReadingFeedbackCategory.generic),
        'Çok genel');
    expect(
      ReadingFeedbackCopy.category(ReadingFeedbackCategory.unanswered),
      'Soruma cevap vermedi',
    );
    expect(ReadingFeedbackCopy.category(ReadingFeedbackCategory.repetitive),
        'Tekrarlı');
    expect(
      ReadingFeedbackCopy.category(ReadingFeedbackCategory.inappropriate),
      'Uygunsuz',
    );
    expect(ReadingFeedbackCopy.retryNote, contains('mücevher'));
  });

  test('store keeps only safe metadata keys', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = ReadingFeedbackStore(storage);
    await store.add(
      ReadingFeedbackEvent(
        feature: ReadingFeedbackFeature.tarot,
        category: ReadingFeedbackCategory.generic,
        ok: true,
        at: DateTime(2026, 8, 20),
      ),
    );
    final json = store.all().single.toJson();
    expect(json.keys.toSet(), ReadingFeedbackEvent.allowedKeys);
    expect(json.containsKey('text'), isFalse);
    expect(json.containsKey('quote'), isFalse);
    expect(json['feature'], 'tarot');
    expect(json['category'], 'generic');
  });

  test('retry does not spend gems', () async {
    SharedPreferences.setMockInitialValues({
      GemWalletStore.balanceKey: 40,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final wallet = GemWalletService(GemWalletStore(storage));
    final charge = GemActionCharge(
      wallet,
      storage,
      ledgerKey: 'tarot_gem_charged_sessions',
    );
    await charge.commit(actionId: 's1', cost: 20, reason: 'tarot');
    final before = wallet.balance;

    final service = ReadingFeedbackService(ReadingFeedbackStore(storage));
    final ok = await service.retryWithoutCharge(
      feature: ReadingFeedbackFeature.tarot,
      category: ReadingFeedbackCategory.missed,
      retry: () async => true,
    );

    expect(ok, isTrue);
    expect(wallet.balance, before);
    expect(charge.alreadyCharged('s1'), isTrue);
    expect(service, isNotNull);
  });
}
