import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/main.dart';

void main() {
  testWidgets('Oracly app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OraclyApp());
    expect(find.byType(OraclyApp), findsOneWidget);
  });
}
