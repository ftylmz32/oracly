/// Quality loop Riverpod wiring.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/backend_providers.dart';
import '../../../core/quality/quality_loop_report.dart';
import '../../../core/quality/quality_loop_reporter.dart';
import '../../../core/quality/quality_signal_recorder.dart';
import '../../../core/quality/quality_signal_store.dart';

final qualitySignalStoreProvider = Provider<QualitySignalStore>((ref) {
  return QualitySignalStore(ref.watch(localStorageProvider));
});

final qualitySignalRecorderProvider = Provider<QualitySignalRecorder>((ref) {
  return QualitySignalRecorder(ref.watch(qualitySignalStoreProvider));
});

final qualityLoopReportProvider = Provider<QualityLoopReport>((ref) {
  return QualityLoopReporter.from(ref.watch(qualitySignalStoreProvider).all());
});
