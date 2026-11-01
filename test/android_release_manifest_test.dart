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
    // Freemium Aşama 3A compiles google_mobile_ads in (ads dark), which
    // merges AD_ID and the Privacy Sandbox ad permissions. Ads are not
    // live, so each is named here ONLY as a tools:node="remove" directive;
    // the compiled-artifact truth is independently verified in
    // android_release_bundle_manifest_test.dart against the merged manifest.
    for (final permission in <String>[
      'com.google.android.gms.permission.AD_ID',
      'android.permission.ACCESS_ADSERVICES_AD_ID',
      'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
      'android.permission.ACCESS_ADSERVICES_TOPICS',
    ]) {
      final named = RegExp(
        '<uses-permission\\s+android:name="${RegExp.escape(permission)}"([^>]*)/>',
      ).allMatches(manifest).toList();
      expect(named, hasLength(1), reason: permission);
      expect(named.single.group(1), contains('tools:node="remove"'), reason: permission);
    }
  });
}
