import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('built release manifest has hardened package and permissions', () {
    final file = File(
      'build/app/intermediates/merged_manifests/release/'
      'processReleaseManifest/AndroidManifest.xml',
    );
    expect(file.existsSync(), isTrue, reason: 'Build the R4B release AAB first.');
    final manifest = file.readAsStringSync();

    expect(manifest, contains('package="app.oracly"'));
    expect(manifest, contains('android:versionCode="1"'));
    expect(manifest, contains('android:versionName="1.0.0"'));
    expect(manifest, isNot(contains('android.permission.READ_EXTERNAL_STORAGE')));
    expect(manifest, isNot(contains('android.permission.WRITE_EXTERNAL_STORAGE')));
    expect(manifest, isNot(contains('com.google.android.gms.permission.AD_ID')));
    expect(
      RegExp(
        r'android:name="android\.hardware\.camera\.any"\s+'
        r'android:required="false"',
      ).hasMatch(manifest),
      isTrue,
    );
  });
}
