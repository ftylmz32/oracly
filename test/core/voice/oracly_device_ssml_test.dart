/// Device SSML is Android Google only — never shown, never sent to HQ.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/oracly_device_ssml.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Google Android turns ellipsis into one think break', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final spoken = OraclyDeviceSsml.maybeWrap(
      'Bir dakika... burada gerçekten ilginç bir şey var.',
      googleAndroid: true,
    );
    expect(spoken.startsWith('<speak>'), isTrue);
    expect(spoken, contains('<break time="380ms"/>'));
    expect(spoken.contains('...'), isFalse);
  });

  test('questions keep their rise mark inside SSML', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final spoken = OraclyDeviceSsml.maybeWrap(
      'Selam, bugün nasılsın?',
      googleAndroid: true,
    );
    expect(spoken, contains('nasılsın?'));
    expect(spoken, isNot(contains('...')));
  });

  test('non-Google never speaks markup', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      OraclyDeviceSsml.maybeWrap(
        'Bir dakika... burada gerçekten ilginç bir şey var.',
        googleAndroid: false,
      ),
      'Bir dakika... burada gerçekten ilginç bir şey var.',
    );
  });
}
