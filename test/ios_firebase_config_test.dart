/// Verifies the real iOS Firebase client plist — no invented options.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String? _plistString(String xml, String key) {
  return RegExp(
    '<key>$key</key>\\s*<string>([^<]*)</string>',
  ).firstMatch(xml)?.group(1);
}

void main() {
  test('iOS Xcode project uses the real app.oracly bundle id, not the '
      'Flutter scaffolding placeholder', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx.contains('PRODUCT_BUNDLE_IDENTIFIER = app.oracly;'), isTrue);
    expect(
      pbx.contains('PRODUCT_BUNDLE_IDENTIFIER = app.oracly.RunnerTests;'),
      isTrue,
    );
    expect(pbx.contains('com.example.oraclyNew'), isFalse);
    expect(pbx.contains('GoogleService-Info.plist in Resources'), isTrue);

    expect(File('lib/firebase_options.dart').existsSync(), isFalse);
    expect(File('ios/Podfile').existsSync(), isFalse);
  });

  test('GoogleService-Info.plist is the real oracly-7f613 Firebase project, '
      'now registered under the correct app.oracly bundle id', () {
    final plist = File('ios/Runner/GoogleService-Info.plist');
    expect(plist.existsSync(), isTrue);

    final xml = plist.readAsStringSync();
    expect(_plistString(xml, 'PROJECT_ID'), 'oracly-7f613');
    expect(_plistString(xml, 'GCM_SENDER_ID'), '1075374196330');
    expect(
      _plistString(xml, 'GOOGLE_APP_ID'),
      startsWith('1:1075374196330:ios:'),
    );
    expect(_plistString(xml, 'BUNDLE_ID'), 'app.oracly');
  });
}
