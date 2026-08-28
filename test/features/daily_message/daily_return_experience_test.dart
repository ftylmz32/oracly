/// P4 daily return — calm reserved note, no fake streak pressure.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/daily_message/copy/daily_message_copy.dart';
import 'package:oracly_new/features/daily_message/data/daily_message_catalogue.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_service.dart';
import 'package:oracly_new/features/daily_rewards/copy/daily_rewards_copy.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('empty-day pool is wide enough to avoid weekly echo', () {
    final pool = DailyMessageCatalogue.dateAware(DateTime(2026, 8, 23));
    expect(pool.length, greaterThanOrEqualTo(14));
    final shapes = {
      for (final line in pool) DailyMessageCatalogue.structureOf(line),
    };
    expect(shapes.length, greaterThanOrEqualTo(6));
  });

  test('empty-day pool localizes for English', () {
    OraclyL10n.bind('en');
    final pool = DailyMessageCatalogue.dateAware(DateTime(2026, 8, 23));
    expect(pool.first.toLowerCase(), isNot(contains('için kısa')));
    expect(
      pool.any((l) => l.toLowerCase().contains('short note') ||
          l.toLowerCase().contains('grand message') ||
          l.toLowerCase().contains('quiet pause')),
      isTrue,
    );
    OraclyL10n.bind('tr');
  });

  test('empty history stays general across a week', () {
    final texts = [
      for (var d = 16; d <= 22; d++)
        DailyMessageService.forDay(day: DateTime(2026, 8, d)).text,
    ];
    expect(texts.toSet().length, greaterThanOrEqualTo(4));
    for (final text in texts) {
      expect(text, isNot(contains('güzel gelişmeler')));
      expect(text, isNot(contains('son keşiflerinde')));
      expect(text.toLowerCase(), isNot(contains('%')));
    }
  });

  test('daily framing feels reserved, not predictive', () {
    expect(DailyMessageCopy.prompt.toLowerCase(), contains('ayr'));
    expect(DailyMessageCopy.listSubtitle.toLowerCase(), contains('ayr'));
    expect(DailyMessageCopy.honesty.toLowerCase(), contains('yansıma'));
    expect(DailyMessageCopy.honesty.toLowerCase(), isNot(contains('kaçırma')));
  });

  test('rewards stay optional gifts without scarcity language', () {
    expect(DailyRewardsCopy.subtitle.toLowerCase(), contains('istersen'));
    expect(DailyRewardsCopy.streakHint.toLowerCase(), contains('bask'));
    expect(DailyRewardsCopy.streakHint.toLowerCase(), contains('kayıp yok'));
    expect(DailyRewardsCopy.claimShort.toLowerCase(), isNot(contains('kaçır')));
    expect(GemsCopy.dailyRewardHint.toLowerCase(), isNot(contains('+50')));
    expect(GemsCopy.dailyRewardHint.toLowerCase(), contains('hediye'));
    expect(GemEconomy.dailyReward, 50);
  });
}
