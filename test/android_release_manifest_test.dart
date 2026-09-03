import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest removes broad storage and keeps camera optional', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('xmlns:tools="http://schemas.android.com/tools"'));
    expect(
      RegExp(r'android:name="android\.permission\.READ_EXTERNAL_STORAGE"[\s\S]*?tools:node="remove"').hasMatch(manifest),
      isTrue,
    );
    expect(
      RegExp(r'android:name="android\.permission\.WRITE_EXTERNAL_STORAGE"[\s\S]*?tools:node="remove"').hasMatch(manifest),
      isTrue,
    );
    expect(
      RegExp(r'android:name="android\.hardware\.camera\.any"[\s\S]*?android:required="false"').hasMatch(manifest),
      isTrue,
    );
    expect(manifest, isNot(contains('com.google.android.gms.permission.AD_ID')));
  });
}
