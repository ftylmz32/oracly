/// Compact Kahve Falı screen — same visual language as Tarot / Dream.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../features/gems/copy/gems_copy.dart';
import '../../../../features/gems/models/paid_ai_operation.dart';
import '../../../../features/gems/providers/gem_providers.dart';
import '../../../../features/gems/services/gem_spend_guard.dart';
import '../../../../features/gems/services/paid_ai_operation_binder.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../controllers/coffee_reading_controller.dart';
import '../../copy/coffee_copy.dart';
import '../../economy/coffee_economy.dart';
import '../../providers/coffee_providers.dart';
import '../../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../../quality_loop/providers/quality_loop_providers.dart';
import '../../../quality_loop/widgets/quality_loop_gate.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../services/coffee_image_validator.dart';
import 'coffee_history_screen.dart';
import 'coffee_landing_chamber.dart';
import 'coffee_reference_body.dart';

class CoffeeReferenceScreen extends ConsumerStatefulWidget {
  const CoffeeReferenceScreen({super.key, this.savedReadingId});

  /// When set, restores that persisted coffee reading on open.
  final String? savedReadingId;

  @override
  ConsumerState<CoffeeReferenceScreen> createState() =>
      _CoffeeReferenceScreenState();
}

class _CoffeeReferenceScreenState extends ConsumerState<CoffeeReferenceScreen> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSavedIfNeeded());
  }

  void _openSavedIfNeeded() {
    final id = widget.savedReadingId?.trim();
    if (id == null || id.isEmpty) return;
    final reading = ref.read(coffeeReadingStoreProvider).byId(id);
    if (reading == null) return;
    ref.read(coffeeReadingControllerProvider).openSaved(reading);
  }

  void _handleBack(CoffeeReadingController controller) {
    if (controller.phase == CoffeePhase.error) {
      ref.read(qualitySignalRecorderProvider).abandonedIfOpen(
            QualityFeature.coffee,
          );
    }
    if (controller.phase == CoffeePhase.capture ||
        controller.phase == CoffeePhase.error ||
        controller.phase == CoffeePhase.result) {
      controller.backToEntry();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CoffeeHistoryScreen()),
    );
  }

  Future<void> _analyze(CoffeeReadingController controller) async {
    if (controller.phase == CoffeePhase.analyzing || _starting) return;
    setState(() => _starting = true);
    try {
      final image = controller.image;
      if (image == null) {
        await controller.analyze();
        return;
      }
      final validation = await CoffeeImageValidator.validate(image.path);
      if (!validation.ok) {
        controller.reportCaptureError(
          validation.message ?? CoffeeCopy.imageUnclear,
        );
        return;
      }
      final tip = validation.guidance;
      if (tip != null && tip.isNotEmpty && mounted) {
        OraclySnackBar.show(context, message: tip);
      }
      if (!mounted) return;
      final op = await GemSpendGuard.beginPaid(
        ref,
        context: context,
        feature: PaidAiFeature.coffee,
        ledgerKey: CoffeeEconomy.ledgerKey,
        reason: GemsCopy.reasonCoffee,
        cost: CoffeeEconomy.analysisCost,
      );
      if (op == null) return;
      if (!mounted) {
        await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
        return;
      }
      ref.read(analyticsServiceProvider).logCoffeeStarted();
      final started = DateTime.now();
      await PaidAiOperationBinder.runWithKey(op.idempotencyKey, () {
        return controller.analyze();
      });
      if (!mounted ||
          controller.phase != CoffeePhase.result ||
          controller.reading == null) {
        await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
        if (controller.phase == CoffeePhase.error) {
          ref.read(analyticsServiceProvider).logCoffeeFailure(
                errorCategory: 'analysis',
              );
        }
        return;
      }
      ref.read(analyticsServiceProvider).logCoffeeSuccess(
            latency: DateTime.now().difference(started),
          );
      await GemSpendGuard.settleOperation(
        ref,
        operation: op,
        context: mounted ? context : null,
      );
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      } else {
        _starting = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(coffeeReadingControllerProvider);
    ref.listen(coffeeReadingControllerProvider, (prev, next) {
      if (prev?.phase != CoffeePhase.result &&
          next.phase == CoffeePhase.result &&
          next.reading != null) {
        PersonalDiscoveryRefresh.invalidate(ref);
      }
      final message = next.errorMessage;
      if ((next.phase == CoffeePhase.capture ||
              next.phase == CoffeePhase.error) &&
          message != null &&
          message != prev?.errorMessage) {
        OraclySnackBar.show(
          context,
          message: AiErrorSanitizer.guard(
            message,
            fallback: CoffeeCopy.analysisFailed,
          ),
        );
      }
    });

    return QualityLoopGate(
      feature: QualityFeature.coffee,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleBack(controller);
        },
        child: CoffeeLandingChamber(
          onBack: () => _handleBack(controller),
          child: CoffeeReferenceBody(
            controller: controller,
            busy: _starting,
            onAnalyze: () => _analyze(controller),
            onHistory: _openHistory,
          ),
        ),
      ),
    );
  }
}
