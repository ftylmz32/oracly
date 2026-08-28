/// Saved Soulmate result provider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../services/soul_mate_result_service.dart';

final soulMateResultServiceProvider = Provider<SoulMateResultService>((ref) {
  return SoulMateResultService(ref.watch(localStorageProvider));
});

final soulMateSavedResultProvider = FutureProvider<bool>((ref) async {
  return ref.watch(soulMateResultServiceProvider).hasSavedResult();
});

final soulMateSavedPortraitProvider = FutureProvider<String?>((ref) async {
  ref.watch(soulMateSavedResultProvider);
  final meta = await ref.watch(soulMateResultServiceProvider).latestMeta();
  if (meta == null) return null;
  final path = meta.portraitPath;
  if (path.isEmpty) return null;
  return path;
});