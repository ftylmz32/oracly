/// Restore/persist hooks for SoulMate draw screen.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/soul_mate_saved_provider.dart';
import '../../data/soul_mate_interpretation_catalogue.dart';
import '../../services/soul_mate_draw_port.dart';
import '../../services/soul_mate_identity.dart';
import '../../services/soul_mate_result_service.dart';

class SoulMateRestoredState {
  const SoulMateRestoredState({
    required this.result,
    required this.savedId,
    required this.name,
    required this.intention,
    required this.birthDate,
    required this.gender,
    this.interpretation,
    this.identity,
  });

  final SoulMateDrawResult result;
  final String savedId;
  final String name;
  final String intention;
  final DateTime birthDate;
  final SoulMateGenderPref? gender;
  final SoulMateReadingParts? interpretation;
  final SoulMateIdentity? identity;
}

abstract final class SoulMateDrawPersistence {
  SoulMateDrawPersistence._();

  static Future<SoulMateRestoredState?> restore(WidgetRef ref) async {
    final loaded =
        await ref.read(soulMateResultServiceProvider).latestWithPortrait();
    if (loaded == null) return null;
    final meta = loaded.meta;
    return SoulMateRestoredState(
      result: SoulMateDrawResult.success(
        imageBytes: loaded.bytes,
        identity: meta.identity,
      ),
      savedId: meta.id,
      name: meta.name,
      intention: meta.intention ?? '',
      birthDate: meta.birthDate,
      gender: meta.gender,
      interpretation:
          meta.hasAuthoritativeInterpretation ? meta.parts : null,
      identity: meta.identity,
    );
  }

  static Future<String?> persistSuccess({
    required WidgetRef ref,
    required SoulMateDrawRequest request,
    required List<int> imageBytes,
  }) async {
    final service = ref.read(soulMateResultServiceProvider);
    return persistWithService(
      service: service,
      request: request,
      imageBytes: imageBytes,
      onSaved: () {
        ref.invalidate(soulMateSavedResultProvider);
        ref.invalidate(soulMateSavedPortraitProvider);
      },
    );
  }

  /// Safe after route dispose — callers must capture [service] before awaiting draw.
  static Future<String?> persistWithService({
    required SoulMateResultService service,
    required SoulMateDrawRequest request,
    required List<int> imageBytes,
    VoidCallback? onSaved,
    String? recordId,
    String? expectedOwnerId,
    SoulMateReadingParts? parts,
    SoulMateIdentity? identity,
  }) async {
    try {
      final saved = await service.saveSuccessfulDraw(
        request: request,
        imageBytes: imageBytes,
        parts: parts,
        recordId: recordId,
        expectedOwnerId: expectedOwnerId,
        identity: identity,
      );
      onSaved?.call();
      return saved?.id;
    } catch (_) {
      return null;
    }
  }
}
