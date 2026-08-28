/// El Falı screen — own feature root, not a Home tile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/design_system/app_layout.dart';
import '../../../features/gems/copy/gems_copy.dart';
import '../../../features/gems/models/paid_ai_operation.dart';
import '../../../features/gems/providers/gem_providers.dart';
import '../../../features/gems/services/gem_spend_guard.dart';
import '../../../features/gems/services/paid_ai_operation_binder.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../controllers/palm_reading_controller.dart';
import '../copy/palm_copy.dart';
import '../economy/palm_economy.dart';
import '../providers/palm_providers.dart';
import '../services/palm_image_validator.dart';
import '../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../quality_loop/providers/quality_loop_providers.dart';
import '../../quality_loop/widgets/quality_loop_gate.dart';
import '../../../core/quality/quality_feature.dart';
import 'palm_atmosphere.dart';
import 'palm_reference_app_bar.dart';
import 'palm_reference_body.dart';
import 'palm_tokens.dart';

class PalmReferenceScreen extends ConsumerStatefulWidget {
  const PalmReferenceScreen({super.key, this.savedReadingId});

  /// When set, restores that persisted palm reading on open.
  final String? savedReadingId;

  @override
  ConsumerState<PalmReferenceScreen> createState() =>
      _PalmReferenceScreenState();
}

class _PalmReferenceScreenState extends ConsumerState<PalmReferenceScreen> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSavedIfNeeded());
  }

  void _openSavedIfNeeded() {
    final id = widget.savedReadingId?.trim();
    if (id == null || id.isEmpty) return;
    final reading = ref.read(palmReadingStoreProvider).byId(id);
    if (reading == null) return;
    ref.read(palmReadingControllerProvider).openSaved(reading);
  }

  void _handleBack(PalmReadingController controller) {
    if (controller.phase == PalmPhase.error) {
      ref.read(qualitySignalRecorderProvider).abandonedIfOpen(
            QualityFeature.palm,
          );
    }
    if (controller.phase == PalmPhase.capture ||
        controller.phase == PalmPhase.error ||
        controller.phase == PalmPhase.result) {
      controller.backToEntry();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  Future<void> _analyze(PalmReadingController controller) async {
    if (controller.phase == PalmPhase.analyzing || _starting) return;
    setState(() => _starting = true);
    try {
      final image = controller.image;
      if (image != null) {
        final check = await PalmImageValidator.validate(image.path);
        if (!check.ok) {
          controller.reportCaptureError(
            check.message ?? PalmCopy.imageTooSmall,
          );
          return;
        }
        if (check.guidance != null && mounted) {
          OraclySnackBar.show(context, message: check.guidance!);
        }
        if (!mounted) return;
      }
      final op = await GemSpendGuard.beginPaid(
        ref,
        context: context,
        feature: PaidAiFeature.palm,
        ledgerKey: PalmEconomy.ledgerKey,
        reason: GemsCopy.reasonPalm,
        cost: PalmEconomy.analysisCost,
      );
      if (op == null) return;
      if (!mounted) {
        await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
        return;
      }
      ref.read(analyticsServiceProvider).logPalmStarted();
      final started = DateTime.now();
      await PaidAiOperationBinder.runWithKey(op.idempotencyKey, () {
        return controller.analyze();
      });
      if (controller.phase != PalmPhase.result || controller.reading == null) {
        await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
        if (controller.phase == PalmPhase.error) {
          ref
              .read(analyticsServiceProvider)
              .logPalmFailure(errorCategory: 'analysis');
        }
        return;
      }
      ref.read(analyticsServiceProvider).logPalmSuccess(
            latency: DateTime.now().difference(started),
          );
      await GemSpendGuard.settleOperation(
        ref,
        operation: op,
        context: mounted ? context : null,
      );
      if (mounted) PersonalDiscoveryRefresh.invalidate(ref);
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
    final controller = ref.watch(palmReadingControllerProvider);
    return QualityLoopGate(
      feature: QualityFeature.palm,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleBack(controller);
        },
        child: OraclyScaffold(
          safeArea: false,
          backgroundOverlay: const PalmAtmosphere(
            child: SizedBox.shrink(),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                PalmTokens.screenHorizontal,
                PalmTokens.screenTop,
                PalmTokens.screenHorizontal,
                AppLayout.scrollBottomInset(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PalmReferenceAppBar(
                    onBack: () => _handleBack(controller),
                  ),
                  SizedBox(height: PalmTokens.gap),
                  Expanded(
                    child: PalmReferenceBody(
                      controller: controller,
                      busy: _starting,
                      onAnalyze: () => _analyze(controller),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
