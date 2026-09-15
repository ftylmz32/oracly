import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/home_greeting_name.dart';

void main() {
  test('live coffee and palm providers do not auto-send recurring themes', () {
    final coffee = File('lib/features/coffee/providers/coffee_providers.dart')
        .readAsStringSync();
    final palm =
        File('lib/features/palm/providers/palm_providers.dart').readAsStringSync();
    expect(coffee.contains('observedRecurringLabels'), isFalse);
    expect(palm.contains('observedRecurringLabels'), isFalse);
    expect(coffee.contains('firstName:'), isTrue);
    expect(palm.contains('firstName:'), isTrue);
  });

  test('firstName still passes and a reading needs no theme', () {
    expect(HomeGreetingName.firstNameOrNull('Fatih'), 'Fatih');
    expect(HomeGreetingName.firstNameOrNull(''), isNull);
  });
}
