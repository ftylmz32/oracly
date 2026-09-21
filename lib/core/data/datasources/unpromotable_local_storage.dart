/// Test-only LocalStorage that never promotes — SharedPreferences unavailable.
library;

import 'package:flutter/foundation.dart';

import 'local_storage.dart';

@visibleForTesting
final class UnpromotableLocalStorage extends LocalStorage {
  UnpromotableLocalStorage([Map<String, Object>? seed]) : super.ephemeral(seed);

  @override
  Future<bool> tryPromote() async => false;
}
