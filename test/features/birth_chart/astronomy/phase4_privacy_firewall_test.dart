/// Phase 4 — privacy: no UTC/coords/owner in share/OR adapters.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OR natal birthLine does not interpolate coords/owner/tz internals', () {
    final src = File(
      'lib/features/ai/oracle_conversation/models/oracle_reading_context_natal.dart',
    ).readAsStringSync();
    expect(src.contains('profile.latitude'), isFalse);
    expect(src.contains('profile.longitude'), isFalse);
    expect(src.contains('profile.timezoneId'), isFalse);
    expect(src.contains('profile.ownerId'), isFalse);
    expect(src.contains('utcInstantIso'), isFalse);
  });
}
