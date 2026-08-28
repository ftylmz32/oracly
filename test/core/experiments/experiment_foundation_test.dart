import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/experiments/experiment_assigner.dart';
import 'package:oracly_new/core/experiments/experiment_assignment_store.dart';
import 'package:oracly_new/core/experiments/experiment_evaluator.dart';
import 'package:oracly_new/core/experiments/experiment_remote_config.dart';
import 'package:oracly_new/core/experiments/experiment_security.dart';
import 'package:oracly_new/core/experiments/experiment_service.dart';
import 'package:oracly_new/core/experiments/product_experiments.dart';
import 'package:oracly_new/core/remote_config/remote_config_runtime.dart';
import 'package:oracly_new/core/remote_config/remote_config_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Experiment foundation', () {
    late LocalStorage storage;
    late ExperimentAssignmentStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await LocalStorage.open();
      store = ExperimentAssignmentStore(storage);
    });

    test('inactive experiments stay on control without remote config', () {
      RemoteConfigRuntime.bind(
        RemoteConfigSnapshot(
          configVersion: 1,
          dailyMessageWeights: const {},
          gemHistoryDisplayLimit: 4,
          featureFlags: const {},
          copyOverrides: const {},
          experiments: const {},
          animationIntensityCap: 'medium',
          notificationCadenceHours: 24,
          notificationDailyHour: 10,
        ),
      );
      final service = ExperimentService(storage: storage);
      expect(
        service.variant(ProductExperiments.coffeeCtaCopy.id),
        ProductExperiments.coffeeCtaCopy.defaultVariant,
      );
      expect(service.isActive(ProductExperiments.coffeeCtaCopy.id), isFalse);
    });

    test('stable assignment persists for the same subject', () {
      const subject = 'subject_alpha';
      final first = ExperimentEvaluator.resolve(
        definition: ProductExperiments.coffeeCtaCopy,
        remoteExperiments: {ProductExperiments.coffeeCtaCopy.id: 'live'},
        store: store,
        subjectId: subject,
      );
      final second = ExperimentEvaluator.resolve(
        definition: ProductExperiments.coffeeCtaCopy,
        remoteExperiments: {ProductExperiments.coffeeCtaCopy.id: 'live'},
        store: store,
        subjectId: subject,
      );
      expect(first, second);
      expect(ProductExperiments.coffeeCtaCopy.isValidVariant(first), isTrue);
    });

    test('different subjects can receive different variants', () {
      final variants = <String>{};
      for (var i = 0; i < 24; i++) {
        variants.add(
          ExperimentAssigner.pick(
            subjectId: 'subject_$i',
            experimentId: ProductExperiments.coffeeCtaCopy.id,
            version: ProductExperiments.coffeeCtaCopy.version,
            variants: ProductExperiments.coffeeCtaCopy.assignmentVariants,
          ),
        );
      }
      expect(variants.length, greaterThan(1));
    });

    test('remote config ignores unknown and financial experiments', () {
      final parsed = ExperimentRemoteConfig.parse({
        'coffee_cta_copy': 'live',
        'home_highlight': 'B',
        'premium_checkout_copy': 'A',
      });
      expect(parsed.keys, ['coffee_cta_copy']);
      expect(ExperimentSecurity.isAllowed('premium_checkout_copy'), isFalse);
    });
  });
}
