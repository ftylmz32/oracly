/// Phase 7 — palm themes enter the profile only from real readings.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

PalmReading _palm({
  required String id,
  required List<String> themes,
  String overall = 'Sakin bir avuç.',
  String? imagePath,
}) {
  return PalmReading(
    id: id,
    createdAt: DateTime(2026, 8, 13),
    hand: PalmHand.right,
    overall: overall,
    themes: themes,
    imagePath: imagePath,
  );
}

void main() {
  test('no palm records keep palm themes empty', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
    );
    expect(profile.palmCount, 0);
    expect(profile.palmThemes, isEmpty);
  });

  test('a single palm theme is not treated as recurring', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        palm: [_palm(id: 'p1', themes: const ['introspection'])],
      ),
    );
    expect(profile.palmCount, 1);
    expect(profile.palmThemes, isEmpty);
  });

  test('two real palm readings can surface an observational theme', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        palm: [
          _palm(id: 'p1', themes: const ['introspection']),
          _palm(id: 'p2', themes: const ['introspection', 'decisiveness']),
        ],
      ),
    );
    expect(profile.palmThemes, contains('içe dönüş'));
    // One modality is not cross-insight "recurring".
    expect(profile.recurringThemes, isEmpty);
  });

  test('store keeps imagePath with the reading by default', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PalmReadingStore(await LocalStorage.open());
    await store.save(
      _palm(
        id: 'p1',
        themes: const ['introspection'],
        imagePath: '/tmp/palm.jpg',
      ),
    );
    expect(store.all().single.imagePath, '/tmp/palm.jpg');
    expect(store.all().single.themes, ['introspection']);
  });
}
