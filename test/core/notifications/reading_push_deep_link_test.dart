import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/notifications/reading_push_bootstrap.dart';

void main() {
  test('completion push identifies the exact Coffee operation', () {
    final id = 'a' * 32;
    final destination = readingPushDestination({
      'type': 'reading_completed',
      'readingType': 'coffee',
      'operationId': id,
    });
    expect(destination?.route, OraclyRoutes.coffee);
    expect(destination?.operationId, id);
  });

  test('completion push identifies the exact Palm operation', () {
    final id = 'b' * 32;
    final destination = readingPushDestination({
      'type': 'reading_completed',
      'readingType': 'palm',
      'operationId': id,
    });
    expect(destination?.route, OraclyRoutes.palm);
    expect(destination?.operationId, id);
  });

  test('non-completion and malformed pushes do not navigate', () {
    expect(readingPushDestination({'type': 'marketing'}), isNull);
    expect(readingPushDestination({
      'type': 'reading_completed',
      'readingType': 'coffee',
      'operationId': 'wrong',
    }), isNull);
  });
}
