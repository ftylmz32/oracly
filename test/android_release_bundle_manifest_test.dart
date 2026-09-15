import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release R8 keeps WorkManager Room database startup entry point', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();

    expect(
      rules,
      contains(
        '-keep class androidx.work.impl.WorkDatabase_Impl { public <init>(); }',
      ),
    );
  });

  test('built release manifest has hardened package and permissions', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final versionMatch = RegExp(
      r'^version:\s*([^+\s]+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(versionMatch, isNotNull, reason: 'pubspec.yaml must declare version+build.');
    final file = File(
      'build/app/intermediates/merged_manifests/release/'
      'processReleaseManifest/AndroidManifest.xml',
    );
    if (!file.existsSync()) {
      markTestSkipped(
        'Release manifest is verified after the immutable freeze seeds the '
        'final AAB build workspace.',
      );
      return;
    }
    final manifest = file.readAsStringSync();

    expect(manifest, contains('package="app.oracly"'));
    expect(
      manifest,
      contains('android:versionCode="${versionMatch!.group(2)}"'),
    );
    expect(
      manifest,
      contains('android:versionName="${versionMatch.group(1)}"'),
    );
    // Every release report must be able to state the shipped SDK floor/target
    // from the artifact itself -- an unexplained minSdk drift (like the
    // undocumented versionCode-3/minSdk-32 build found outside this repo's
    // own evidence trail) fails this gate immediately instead of surfacing
    // only via a manual `adb`/device inspection after the fact.
    expect(manifest, contains('android:minSdkVersion="24"'));
    expect(manifest, contains('android:targetSdkVersion="36"'));
    expect(
      manifest,
      isNot(contains('android.permission.READ_EXTERNAL_STORAGE')),
    );
    expect(
      manifest,
      isNot(contains('android.permission.WRITE_EXTERNAL_STORAGE')),
    );
    expect(
      manifest,
      isNot(contains('com.google.android.gms.permission.AD_ID')),
    );
    // Modern Privacy Sandbox equivalents of AD_ID -- google_mobile_ads (or
    // any other AdServices-based ad SDK) merges these in even when the
    // legacy AD_ID permission is suppressed. Rewarded ads are not shipping
    // in this release, so the ad SDK itself must not be compiled in at all
    // (see pubspec.yaml) -- these must stay absent, not just hidden.
    expect(
      manifest,
      isNot(contains('android.permission.ACCESS_ADSERVICES_AD_ID')),
    );
    expect(
      manifest,
      isNot(contains('android.permission.ACCESS_ADSERVICES_ATTRIBUTION')),
    );
    expect(
      manifest,
      isNot(contains('android.permission.ACCESS_ADSERVICES_TOPICS')),
    );
    expect(manifest, isNot(contains('android.ext.adservices')));
    expect(
      manifest,
      isNot(contains('com.google.android.gms.ads.MobileAdsInitProvider')),
    );
    expect(
      manifest,
      isNot(contains('com.google.android.gms.ads.APPLICATION_ID')),
    );
    expect(
      RegExp(
        r'android:name="android\.hardware\.camera\.any"\s+'
        r'android:required="false"',
      ).hasMatch(manifest),
      isTrue,
    );
  });
}
