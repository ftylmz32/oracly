/// PalmReadingStore keeps takeaway and imagePath.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('store persists takeaway and imagePath', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PalmReadingStore(LocalStorage.ephemeral());
    await store.save(
      PalmReading(
        id: 'palm_store_1',
        createdAt: DateTime(2026, 8, 27),
        hand: PalmHand.right,
        overall: 'Sakin bir avuç.',
        takeaway: 'En önemli işaret denge.',
        imagePath: '/docs/palm_images/palm_store_1.jpg',
      ),
    );
    final loaded = store.byId('palm_store_1');
    expect(loaded, isNotNull);
    expect(loaded!.takeaway, 'En önemli işaret denge.');
    expect(loaded.imagePath, '/docs/palm_images/palm_store_1.jpg');
  });
}
