/// Single Home NextAction surface — evidence only, never inventing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../oracle_core/models/oracle_next_action.dart';
import '../../oracle_core/providers/oracle_core_providers.dart';
import '../../oracle_core/services/oracle_journey_premium_copy.dart';
import '../../oracle_core/services/oracle_next_action_copy.dart';
import 'home_oracle_next_action_body.dart';

class HomeOracleNextActionCard extends ConsumerStatefulWidget {
  const HomeOracleNextActionCard({super.key});

  @override
  ConsumerState<HomeOracleNextActionCard> createState() =>
      _HomeOracleNextActionCardState();
}

class _HomeOracleNextActionCardState
    extends ConsumerState<HomeOracleNextActionCard> {
  OracleNextAction? _held;
  String? _recordedId;
  bool _scheduled = false;

  OracleNextAction? get _action {
    final live = ref.watch(oracleNextActionProvider);
    final candidate = _held ?? live;
    if (candidate == null || !candidate.hasEvidence) return null;
    return candidate;
  }

  Future<void> _ensureShown(OracleNextAction action) async {
    if (!mounted || _recordedId == action.nextActionId) return;
    _recordedId = action.nextActionId;
    _held = action;
    await markOracleNextActionShown(
      ref.read(oracleNextActionMemoryProvider),
      action,
    );
    if (!mounted) return;
    ref.invalidate(oracleNextActionProvider);
  }

  Future<void> _dismiss(OracleNextAction action) async {
    await markOracleNextActionDismissed(
      ref.read(oracleNextActionMemoryProvider),
      action,
    );
    if (!mounted) return;
    setState(() {
      _held = null;
      _recordedId = action.nextActionId;
    });
    ref.invalidate(oracleNextActionProvider);
  }

  Future<void> _open(OracleNextAction action) async {
    await _ensureShown(action);
    if (!mounted) return;
    OraclyFeatureNavigation.open(
      context,
      action.recommendedFeature.featureId,
    );
    if (!mounted) return;
    setState(() => _held = null);
  }

  @override
  Widget build(BuildContext context) {
    final action = _action;
    if (action == null) return const SizedBox.shrink();

    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureShown(action);
      });
    }

    final access = ref.watch(oracleJourneyDepthAccessProvider);
    final archive = ref.watch(oracleJourneyArchiveProvider);
    String? archiveLine;
    if (access.allowJourneyArchive && archive != null && archive.isNotEmpty) {
      final top = archive.entries.first;
      archiveLine = OracleJourneyPremiumCopy.archiveSummary(
        theme: OracleNextActionCopy.themeLabel(action),
        sources: top.sourceFeatures.length,
        occurrences: top.occurrenceCount,
      );
    }

    return HomeOracleNextActionBody(
      title: OracleNextActionCopy.homeTitle(action),
      body: OracleNextActionCopy.homeBody(action),
      cta: OracleNextActionCopy.homeCta(action),
      dismissLabel: OracleNextActionCopy.homeDismiss(),
      onOpen: () => _open(action),
      onDismiss: () => _dismiss(action),
      archiveLine: archiveLine,
      premiumHint: access.allowSoftPremiumInvite
          ? OracleJourneyPremiumCopy.softBody(action)
          : null,
      premiumCta: access.allowSoftPremiumInvite
          ? OracleJourneyPremiumCopy.softCta()
          : null,
      onPremium: access.allowSoftPremiumInvite
          ? () => OraclyNavigationService.openPremium(context)
          : null,
    );
  }
}
