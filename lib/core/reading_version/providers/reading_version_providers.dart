/// Reading version service provider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../services/reading_version_service.dart';
import '../services/reading_version_store.dart';

final readingVersionStoreProvider = Provider<ReadingVersionStore>((ref) {
  return ReadingVersionStore(ref.watch(localStorageProvider));
});

final readingVersionServiceProvider = Provider<ReadingVersionService>((ref) {
  return ReadingVersionService(ref.watch(readingVersionStoreProvider));
});

