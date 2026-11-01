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
    final manifest = file.readAsStringSync().replaceAll('\r\n', '\n');

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
    // Modern Privacy Sandbox equivalents of AD_ID -- google_mobile_ads
    // merges these in even when the legacy AD_ID permission is suppressed.
    // Ads are not live, so they must be absent from the shipped artifact.
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
    // Freemium Aşama 3A/3B (PO decision): google_mobile_ads 9.1.0 is
    // compiled in but dormant behind the ads gate (default-off ads_v1 and,
    // in release, ORACLY_ADS_RELEASE_APPROVED). Its components may appear
    // only together with ORACLY's real app id (never Google's sample id) and
    // delayed measurement. The optional Privacy Sandbox library stays
    // required="false" so no device is excluded.
    expect(
      manifest,
      contains(
        'android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
        '            android:value="ca-app-pub-8094570449180229~6192956874"',
      ),
    );
    expect(manifest, isNot(contains('ca-app-pub-3940256099942544')));
    expect(
      manifest,
      contains(
        'android:name="com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT"\n'
        '            android:value="true"',
      ),
    );
    expect(
      manifest,
      contains(
        'android:name="android.ext.adservices"\n'
        '            android:required="false"',
      ),
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
