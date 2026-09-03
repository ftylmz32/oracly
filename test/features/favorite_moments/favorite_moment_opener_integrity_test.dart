/// Favorite opener integrity after privacy history clear.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_snapshot.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('valid tarot snapshot builds history entry fallback', () {
    final moment = FavoriteMoment(
      id: 'tarot:r1',
      source: FavoriteMomentSource.tarot,
      sourceRef: 'r1',
      savedAt: _t,
      occurredAt: _t,
      quote: 'Saved insight stays readable.',
      visualAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      visualLabel: 'Yildiz',
    );
    expect(FavoriteMomentSnapshot.canShowFallback(moment), isTrue);
    expect(FavoriteMomentSnapshot.tarotHistoryEntry(moment)?.cardName, 'Yildiz');
  });

  test('insufficient tarot snapshot is unavailable', () {
    final moment = FavoriteMoment(
      id: 'tarot:r2',
      source: FavoriteMomentSource.tarot,
      sourceRef: 'r2',
      savedAt: _t,
      occurredAt: _t,
      quote: 'Only quote',
    );
    expect(FavoriteMomentSnapshot.canShowFallback(moment), isFalse);
    expect(FavoriteMomentSnapshot.tarotHistoryEntry(moment), isNull);
  });

  test('dream coffee palm quote-only snapshots can fallback', () {
    for (final source in [
      FavoriteMomentSource.dream,
      FavoriteMomentSource.coffee,
      FavoriteMomentSource.palm,
    ]) {
      final moment = FavoriteMoment(
        id: source.name + ':x',
        source: source,
        sourceRef: 'x',
        savedAt: _t,
        occurredAt: _t,
        quote: 'Saved excerpt',
      );
      expect(FavoriteMomentSnapshot.canShowFallback(moment), isTrue);
    }
  });

  test('unavailable copy is localized', () {
    expect(
      FavoriteMomentsCopy.sourceUnavailable,
      contains('Kaynak okuma'),
    );
  });
}

final _t = DateTime(2026, 1, 1);
