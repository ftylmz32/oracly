/// The server's own "daily quota" answers, kept for this signed-in owner
/// and this server (UTC) day only, plus the resolved allowance per kind.
/// An account switch starts empty; nothing is persisted, so a refunded
/// slot is never hidden behind an old answer across app starts.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/backend_providers.dart';
import '../../premium/providers/premium_providers.dart';
import '../models/reading_allowance.dart';

class ReadingAllowanceSignals extends ChangeNotifier {
  ReadingAllowanceSignals({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<ReadingAllowanceKind, String> _usedOn = {};

  static String _serverDay(DateTime at) =>
      at.toUtc().toIso8601String().substring(0, 10);

  bool usedToday(ReadingAllowanceKind kind) =>
      _usedOn[kind] == _serverDay(_now());

  /// Called only with an exact server daily-quota answer.
  void markUsed(ReadingAllowanceKind kind) {
    final day = _serverDay(_now());
    if (_usedOn[kind] == day) return;
    _usedOn[kind] = day;
    notifyListeners();
  }

  /// A new create was accepted, or the user asked to check again.
  void clear(ReadingAllowanceKind kind) {
    if (_usedOn.remove(kind) != null) notifyListeners();
  }
}

final readingAllowanceSignalsProvider =
    ChangeNotifierProvider<ReadingAllowanceSignals>((ref) {
  ref.watch(localDataOwnerEpochProvider);
  return ReadingAllowanceSignals();
});

final readingAllowanceProvider =
    Provider.family<ReadingAllowanceView, ReadingAllowanceKind>((ref, kind) {
  final premium = ref.watch(premiumStatusProvider);
  final signals = ref.watch(readingAllowanceSignalsProvider);
  return resolveReadingAllowance(
    kind: kind,
    loaded: premium.loaded,
    busy: premium.busy,
    isPremium: premium.isPremium,
    entitlement: premium.entitlement,
    usedToday: signals.usedToday(kind),
  );
});
