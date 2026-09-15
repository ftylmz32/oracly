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
    // Rewarded ads are not shipping this release, so google_mobile_ads was
    // removed from the dependency graph entirely (pubspec.yaml) -- there is
    // no longer any library merging AD_ID in, so a manifest-level removal
    // directive for it is dead cruft, not a needed defense. Absence here is
    // a strictly stronger guarantee than "present but tools:remove"; the
    // compiled-artifact truth is independently verified in
    // android_release_bundle_manifest_test.dart against the real merged
    // manifest, including the modern AdServices permissions this predates.
    expect(
      manifest,
      isNot(contains('com.google.android.gms.permission.AD_ID')),
    );
  });
}
