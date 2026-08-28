/// Resolves OR styleHint from Oracle Core, then Discovery compact context.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../oracle_core/providers/oracle_core_providers.dart';
import '../../oracle_core/services/oracle_next_action_engine.dart';
import '../../oracle_core/services/oracle_or_style_hint.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';

Future<String?> companionOrStyleHint(Ref ref, String message) async {
  try {
    final profile = await ref
        .read(personalDiscoveryProfileProvider.future)
        .timeout(const Duration(seconds: 3));
    final next = OracleNextActionEngine.decide(
      profile,
      memory: ref.read(oracleNextActionMemoryProvider),
    );
    final deep = ref.read(oracleJourneyDepthAccessProvider).allowDeepOrContext;
    return OracleOrStyleHint.forMessage(
      profile,
      message,
      nextAction: next,
      deep: deep,
    );
  } catch (_) {
    return null;
  }
}
