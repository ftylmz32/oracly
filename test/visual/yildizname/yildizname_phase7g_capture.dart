/// Phase 7G — shared capture helper for final masters (test-only).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yildizname_golden_harness.dart';

Future<void> phase7gCapture(
  WidgetTester tester,
  String name,
  Future<GlobalKey> Function() pump, {
  void Function()? assertAfter,
}) async {
  final key = await pump();
  assertAfter?.call();
  await yildiznamePhase7gGoldenExpect(tester, key, name);
}
