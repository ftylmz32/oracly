/// Verifies the official ORACLY logo is present for launcher + splash.
///
/// Do not regenerate circular temporary marks. Copy from
/// `assets/brand/oracly_launcher_source.png` when updating the master.
///
/// Run: `flutter test tool/oracly_brand/export_brand_mark_test.dart`
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official logo asset is present and substantial', () {
    final root = Directory.current.path;
    final logo = File('$root/lib/assets/brand/oracly_logo.png');
    final master = File('$root/assets/brand/oracly_launcher_source.png');
    expect(logo.existsSync(), isTrue);
    expect(master.existsSync(), isTrue);
    expect(logo.lengthSync(), greaterThan(50 * 1024));
    expect(master.lengthSync(), greaterThan(50 * 1024));
  });

  test('legacy circular temporary marks are not shipped', () {
    final brand = Directory('${Directory.current.path}/lib/assets/brand');
    final names = brand
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
    expect(names, contains('oracly_logo.png'));
    expect(
      names.where((n) => n.startsWith('oracly_mark_')),
      isEmpty,
      reason: 'Temporary circular marks must not ship as brand assets',
    );
  });

  test('Android adaptive foreground uses regenerated launcher assets', () {
    final fg = File(
      '${Directory.current.path}/android/app/src/main/res/'
      'drawable-xxxhdpi/ic_launcher_foreground.png',
    );
    expect(fg.existsSync(), isTrue);
    expect(fg.lengthSync(), greaterThan(20 * 1024));
  });
}
