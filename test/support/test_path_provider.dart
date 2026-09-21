/// Shared PathProvider mock for wipe/deletion unit tests.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

Future<Directory> installTestPathProvider([String prefix = 'oracly-pp-']) async {
  final root = await Directory.systemTemp.createTemp(prefix);
  PathProviderPlatform.instance = TestPathProvider(root.path);
  return root;
}

class TestPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  TestPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}
