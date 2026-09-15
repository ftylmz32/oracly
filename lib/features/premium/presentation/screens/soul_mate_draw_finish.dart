/// Apply a Soulmate generation result without wiping a prior portrait.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../discovery_journal/providers/discovery_journal_providers.dart';
import '../../providers/soul_mate_saved_provider.dart';
import '../../services/soul_mate_draw_action.dart';
import '../../services/soul_mate_draw_port.dart';
import '../../services/soul_mate_result_service.dart';
import 'soul_mate_draw_persistence.dart';

class SoulMateDrawFinish {
  const SoulMateDrawFinish({
    required this.busy,
    required this.result,
    required this.statusMessage,
    required this.savedId,
  });

  final bool busy;
  final SoulMateDrawResult? result;
  final String? statusMessage;
  final String? savedId;

  static SoulMateDrawFinish declined() => const SoulMateDrawFinish(
        busy: false,
        result: null,
        statusMessage: null,
        savedId: null,
      );

  static Future<SoulMateDrawFinish> apply({
    required SoulMateDrawResult? result,
    required String? savedId,
  }) async {
    if (result == null || result.declined) return declined();
    if (!result.hasPortrait || result.imageBytes == null) {
      return SoulMateDrawFinish(
        busy: false,
        result: result,
        statusMessage: SoulMateDrawAction.visibleMessage(result),
        savedId: savedId,
      );
    }
    return SoulMateDrawFinish(
      busy: false,
      result: result,
      statusMessage: null,
      savedId: savedId,
    );
  }

  static Future<String?> persist({
    required WidgetRef ref,
    required SoulMateDrawResult result,
    required SoulMateDrawRequest? request,
    required SoulMateDrawRequest? formRequest,
    SoulMateResultService? service,
    String? ownerId,
    required bool mounted,
  }) async {
    if (!result.hasPortrait || result.imageBytes == null) return null;
    final draw = request ?? formRequest ?? SoulMateDrawAction.requestFromSession(ref);
    if (draw == null) return null;
    return SoulMateDrawPersistence.persistWithService(
      service: service ?? ref.read(soulMateResultServiceProvider),
      request: draw,
      imageBytes: result.imageBytes!,
      recordId: result.operationId,
      expectedOwnerId: ownerId ?? SoulMateDrawAction.ownerOf(ref),
      onSaved: mounted
          ? () {
              ref.invalidate(soulMateSavedResultProvider);
              ref.invalidate(soulMateSavedPortraitProvider);
              _refreshJournal(ref);
            }
          : null,
    );
  }

  static void _refreshJournal(WidgetRef ref) {
    try {
      ref.invalidate(discoveryJournalEntriesProvider);
    } catch (_) {}
  }
}
