/// Resolves OR styleHint from Oracle Core, then Discovery compact context.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../oracle_core/providers/oracle_core_providers.dart';
import '../../oracle_core/services/oracle_next_action_engine.dart';
import '../../oracle_core/services/oracle_or_style_hint.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../../core/memory/oracly_memory_retriever.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../../../core/providers/backend_providers.dart';

Future<String?> companionOrStyleHint(Ref ref, String message) async {
  String? discovery;
  try {
    final profile = await ref
        .read(personalDiscoveryProfileProvider.future)
        .timeout(const Duration(seconds: 3));
    final next = OracleNextActionEngine.decide(
      profile,
      memory: ref.read(oracleNextActionMemoryProvider),
    );
    final deep = ref.read(oracleJourneyDepthAccessProvider).allowDeepOrContext;
    discovery = OracleOrStyleHint.forMessage(
      profile,
      message,
      nextAction: next,
      deep: deep,
    );
  } catch (_) {}
  final packet = OraclyMemoryRetriever(
    OraclyMemoryStore(ref.read(localStorageProvider)),
  ).retrieve(query: message);
  final connected = packet.toPrompt();
  final result = [
    discovery,
    if (connected.isNotEmpty) connected,
  ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' ');
  return result.isEmpty ? null : result;
}
