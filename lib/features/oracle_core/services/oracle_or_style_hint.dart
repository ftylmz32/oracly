/// Prefers Oracle Core evidence, then Discovery OR compact context.
library;

import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/services/discovery_or_context.dart';
import '../models/oracle_next_action.dart';
import 'oracle_or_context.dart';

abstract final class OracleOrStyleHint {
  OracleOrStyleHint._();

  static String? forMessage(
    PersonalDiscoveryProfile profile,
    String userMessage, {
    OracleNextAction? nextAction,
    Set<String>? allowedSources,
    DateTime? now,
    bool deep = false,
  }) =>
      OracleOrContext.forMessage(
        profile,
        userMessage,
        nextAction: nextAction,
        allowedSources: allowedSources,
        now: now,
        deep: deep,
      ) ??
      DiscoveryOrContext.compactForMessage(profile, userMessage);
}
