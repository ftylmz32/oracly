/// 78 unique ORACLY card art files — runtime WebP.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_assets.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';

void main() {
  test('78 unique runtime card faces exist', () {
    final hashes = <int>{};
    for (final card in OraclyTarotDeck.all) {
      expect(card.visualAsset, startsWith(OraclyTarotAssets.cardsRoot));
      final file = File(card.visualAsset);
      expect(file.existsSync(), isTrue, reason: card.visualAsset);
      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(8 * 1024), reason: card.id);
      var hash = bytes.length;
      for (var i = 0; i < bytes.length; i += 17) {
        hash = 0x1fffffff & (hash + bytes[i] * (i + 3));
      }
      hashes.add(hash);
    }
    expect(OraclyTarotDeck.all, hasLength(78));
    expect(hashes, hasLength(78));
  });
}
