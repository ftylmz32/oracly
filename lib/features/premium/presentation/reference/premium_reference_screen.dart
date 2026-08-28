/// Premium invitation screen — visual shell, honest store state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/audio/oracly_feedback_gate.dart';
import '../../../../core/audio/oracly_sound_chamber.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/navigation/oracly_page_transitions.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../models/premium_purchase_result.dart';
import '../../providers/premium_providers.dart';
import 'premium_reference_app_bar.dart';
import 'premium_reference_atmosphere.dart';
import 'premium_reference_body.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceScreen extends ConsumerStatefulWidget {
  const PremiumReferenceScreen({super.key});

  @override
  ConsumerState<PremiumReferenceScreen> createState() =>
      _PremiumReferenceScreenState();
}

class _PremiumReferenceScreenState
    extends ConsumerState<PremiumReferenceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(premiumStatusProvider).load();
      ref.read(analyticsServiceProvider).logPremiumViewed();
    });
  }

  Future<void> _purchase() async {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logOperation(operation: 'premium_purchase_started', success: true);
    analytics.logOperation(
      operation: 'premium_plan_selected',
      success: true,
      errorCategory: ref.read(premiumStatusProvider).selectedPlan.name,
    );
    await _finish(await ref.read(premiumStatusProvider).purchase());
  }

  Future<void> _restore() async {
    ref.read(analyticsServiceProvider).logOperation(
          operation: 'premium_restore_started',
          success: true,
        );
    await _finish(
      await ref.read(premiumStatusProvider).restore(),
      restore: true,
    );
  }

  Future<void> _finish(
    PremiumPurchaseResult result, {
    bool restore = false,
  }) async {
    if (!mounted) return;
    final analytics = ref.read(analyticsServiceProvider);
    ref.invalidate(premiumActiveProvider);
    ref.invalidate(userProfileProvider);
    if (result.granted) {
      analytics.logPremiumActivated(result.plan?.name ?? 'unknown');
      analytics.logOperation(
        operation:
            restore ? 'premium_restore_completed' : 'premium_purchase_completed',
        success: true,
      );
      OraclyFeedbackGate.playCue(OraclySoundCue.premiumPurchase);
      OraclySnackBar.success(context, result.message);
      return;
    }
    final cancelled = result.outcome == PremiumPurchaseOutcome.cancelled;
    final soft = cancelled ||
        result.outcome == PremiumPurchaseOutcome.pending ||
        result.outcome == PremiumPurchaseOutcome.noneFound ||
        result.outcome == PremiumPurchaseOutcome.unverified;
    analytics.logOperation(
      operation: restore
          ? 'premium_restore_completed'
          : cancelled
              ? 'premium_purchase_cancelled'
              : 'premium_purchase_failed',
      success: soft,
      errorCategory: result.outcome.name,
    );
    if (soft) {
      OraclySnackBar.success(context, result.message);
      return;
    }
    OraclySnackBar.error(context, result.message);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(premiumStatusProvider);
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const PremiumReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                PremiumReferenceTokens.screenHorizontal,
                PremiumReferenceTokens.screenTop,
                PremiumReferenceTokens.screenHorizontal,
                0,
              ),
              child: PremiumReferenceAppBar(
                onBack: () => Navigator.of(context).maybePop(),
                onGemTap: () => OraclyNavigationService.openGems(context),
              ),
            ),
            Expanded(
              child: PremiumReferenceBody(
                status: status,
                onPurchase: _purchase,
                onRestore: _restore,
                onRetryStore: () => ref.read(premiumStatusProvider).load(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Route<T> premiumScreenRoute<T>({RouteSettings? settings}) {
  return OraclyPageTransitions.light<T>(
    page: const PremiumReferenceScreen(),
    settings: settings,
  );
}
