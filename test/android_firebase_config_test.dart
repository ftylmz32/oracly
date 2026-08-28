/// Verifies the real Android Firebase client file — no invented options.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('google-services.json matches applicationId and project oracly-7f613',
      () {
    final jsonFile = File('android/app/google-services.json');
    expect(jsonFile.existsSync(), isTrue);

    final data = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
    final info = data['project_info'] as Map<String, dynamic>;
    expect(info['project_id'], 'oracly-7f613');

    final clients = data['client'] as List<dynamic>;
    final packages = clients
        .map(
          (c) => (((c as Map)['client_info'] as Map?)?['android_client_info']
              as Map?)?['package_name'],
        )
        .toList();
    expect(packages, contains('app.oracly'));

    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle.contains('applicationId = "app.oracly"'), isTrue);
    expect(gradle.contains('id("com.google.gms.google-services")'), isTrue);

    final settings = File('android/settings.gradle.kts').readAsStringSync();
    expect(settings.contains('com.google.gms.google-services'), isTrue);

    expect(File('lib/firebase_options.dart').existsSync(), isFalse);
  });
}
