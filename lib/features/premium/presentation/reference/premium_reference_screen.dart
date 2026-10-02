/// Premium invitation screen — visual shell, honest store state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/navigation/oracly_page_transitions.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../models/premium_purchase_result.dart';
import '../../providers/premium_providers.dart';
import 'premium_reference_app_bar.dart';
import 'premium_reference_atmosphere.dart';
import 'premium_reference_body.dart';
import 'premium_reference_outcome.dart';
import 'premium_reference_tokens.dart';
import 'premium_store_diagnostics_sheet.dart';

class PremiumReferenceScreen extends ConsumerStatefulWidget {
  const PremiumReferenceScreen({super.key});

  @override
  ConsumerState<PremiumReferenceScreen> createState() =>
      _PremiumReferenceScreenState();
}

class _PremiumReferenceScreenState
    extends ConsumerState<PremiumReferenceScreen> {
  int _purchaseEpoch = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(premiumStatusProvider).load();
      ref.read(analyticsServiceProvider).logPremiumViewed();
    });
  }

  Future<void> _purchase() async {
    _purchaseEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logOperation(
      operation: 'premium_purchase_started',
      success: true,
    );
    analytics.logOperation(
      operation: 'premium_plan_selected',
      success: true,
      errorCategory: ref.read(premiumStatusProvider).selectedPlan.name,
    );
    await _finish(await ref.read(premiumStatusProvider).purchase());
  }

  Future<void> _restore() async {
    _purchaseEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    ref
        .read(analyticsServiceProvider)
        .logOperation(operation: 'premium_restore_started', success: true);
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
    if (UserLocalDataIsolation.accountSwitchEpoch.value != _purchaseEpoch) {
      return;
    }
    await finishPremiumReferenceOutcome(ref, context, result, restore: restore);
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
                onRetryStore: () => ref.read(premiumStatusProvider).retryStore(),
                onStoreDiagnostics: () => showPremiumStoreDiagnostics(
                  context,
                  ref.read(premiumPurchasePortProvider),
                ),
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
