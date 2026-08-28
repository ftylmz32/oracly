/// Oracle Core Riverpod wiring - read-only over Personal Discovery.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../data/oracle_next_action_memory.dart';
import '../models/oracle_next_action.dart';
import '../models/oracle_next_action_event.dart';
import '../../premium/providers/premium_providers.dart';
import '../models/oracle_journey_archive.dart';
import '../models/oracle_journey_depth_access.dart';
import '../models/oracle_premium_opportunity.dart';
import '../services/oracle_journey_archive_builder.dart';
import '../services/oracle_journey_depth_gate.dart';
import '../services/oracle_next_action_engine.dart';

final oracleNextActionMemoryProvider = Provider<OracleNextActionMemory>(
  (ref) => OracleNextActionMemory(ref.watch(localStorageProvider)),
  dependencies: [localStorageProvider],
);

final oracleNextActionProvider = Provider<OracleNextAction?>(
  (ref) {
    final profile = ref.watch(personalDiscoveryProfileProvider).valueOrNull ??
        PersonalDiscoveryProfile.empty;
    final memory = ref.watch(oracleNextActionMemoryProvider);
    return OracleNextActionEngine.decide(profile, memory: memory);
  },
  dependencies: [
    personalDiscoveryProfileProvider,
    oracleNextActionMemoryProvider,
  ],
);

Future<void> markOracleNextActionShown(
  OracleNextActionMemory memory,
  OracleNextAction action,
) {
  return memory.record(
    OracleNextActionEvent(
      theme: action.theme,
      feature: action.recommendedFeature.name,
      at: action.generatedAt,
      kind: 'shown',
      evidenceIds: action.evidenceIds,
    ),
  );
}

Future<void> markOracleNextActionDismissed(
  OracleNextActionMemory memory,
  OracleNextAction action, {
  DateTime? at,
}) {
  return memory.record(
    OracleNextActionEvent(
      theme: action.theme,
      feature: action.recommendedFeature.name,
      at: at ?? DateTime.now(),
      kind: 'dismissed',
      evidenceIds: action.evidenceIds,
    ),
  );
}

final oracleJourneyDepthAccessProvider = Provider<OracleJourneyDepthAccess>(
  (ref) {
    final profile = ref.watch(personalDiscoveryProfileProvider).valueOrNull ??
        PersonalDiscoveryProfile.empty;
    final action = ref.watch(oracleNextActionProvider);
    final premium = ref.watch(premiumStatusProvider).isPremium;
    final ready = OracleJourneyArchiveBuilder.isJourneyReady(profile);
    return OracleJourneyDepthGate.resolve(
      opportunity: action?.premiumOpportunity ?? OraclePremiumOpportunity.none,
      hasEvidence: action?.hasEvidence ?? false,
      isPremium: premium,
      journeyReady: ready,
    );
  },
  dependencies: [
    personalDiscoveryProfileProvider,
    oracleNextActionProvider,
    premiumStatusProvider,
  ],
);

final oracleJourneyArchiveProvider = Provider<OracleJourneyArchive?>(
  (ref) {
    final access = ref.watch(oracleJourneyDepthAccessProvider);
    if (!access.allowJourneyArchive) return null;
    final profile = ref.watch(personalDiscoveryProfileProvider).valueOrNull ??
        PersonalDiscoveryProfile.empty;
    return OracleJourneyArchiveBuilder.fromProfile(profile);
  },
  dependencies: [
    oracleJourneyDepthAccessProvider,
    personalDiscoveryProfileProvider,
  ],
);
