/// Phase 6F — remote `false` restores the legacy AI Tarot path, and an
/// unconfigured Narrative interpreter fails closed instead of silently
/// falling back. REAL PROVIDER CALLS = 0.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';

import '../narrative_history/tarot_4c_test_support.dart';

void _setFlag(bool enabled) => FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: enabled,
    });

List<File> _libDartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('flag OFF removes Narrative routing for every launch spread', () {
    _setFlag(false);
    for (final type in const [
      TarotSpreadType.single,
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
    ]) {
      expect(NarrativeTarotLiveGate.shouldUseNarrative(type), isFalse);
      expect(NarrativeTarotLiveGate.isLaunchSpread(type), isTrue);
    }
  });

  test('flag ON without a configured interpreter fails closed', () async {
    _setFlag(true);
    final service = TarotInterpretationService();
    await expectLater(
      service.generateResult(completedSession(id: 'sess_rollback_on')),
      throwsA(
        isA<InterpretationException>().having(
          (e) => e.retryable,
          'retryable',
          isFalse,
        ),
      ),
    );
  });

  test('flag OFF routes the same session through the legacy engine', () async {
    _setFlag(false);
    final service = TarotInterpretationService();
    final result = await service.generateResult(
      completedSession(id: 'sess_rollback_off'),
    );
    expect(result.summary.trim(), isNotEmpty);
  });

  test('cache invalidation stays safe without a Narrative interpreter',
      () async {
    _setFlag(true);
    final service = TarotInterpretationService();
    await service.invalidateCache(completedSession(id: 'sess_rollback_inv'));
  });

  group('generateStream has no production callers', () {
    test('declared once, under tarot_interpretation_service.dart', () {
      final declaring = <String>[];
      final callers = <String>[];
      for (final file in _libDartFiles()) {
        final source = file.readAsStringSync();
        if (source.contains(
          'Stream<InterpretationStreamEvent> generateStream(',
        )) {
          declaring.add(file.path);
        }
        if (source.contains('.generateStream(')) {
          callers.add(file.path);
        }
      }
      expect(declaring, hasLength(1));
      expect(
        declaring.single.replaceAll(r'\', '/'),
        endsWith('lib/features/tarot/services/tarot_interpretation_service.dart'),
      );
      expect(callers, isEmpty);
    });

    test('Narrative-eligible sessions error instead of streaming legacy',
        () async {
      _setFlag(true);
      final service = TarotInterpretationService();
      await expectLater(
        service.generateStream(completedSession(id: 'sess_rollback_stream')),
        emitsError(isA<InterpretationException>()),
      );
    });
  });
}
