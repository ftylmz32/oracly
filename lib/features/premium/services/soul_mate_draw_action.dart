/// Screen entry for one Soulmate generation ? joins in-flight, never forks it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../copy/soul_mate_copy.dart';
import 'soul_mate_draw_port.dart';
import 'soul_mate_generation_session.dart';
import 'soul_mate_paid_draw.dart';

abstract final class SoulMateDrawAction {
  SoulMateDrawAction._();

  static String ownerOf(WidgetRef ref) {
    final stored = ref.read(localStorageProvider).getString(
          UserLocalDataIsolation.ownerKey,
        );
    if (stored == null || stored.trim().isEmpty) return 'local';
    return stored;
  }

  static SoulMateDrawRequest? requestFromSession(WidgetRef ref) {
    final owner = ownerOf(ref);
    final record = SoulMateGenerationSessionStore.read(
      ref.read(localStorageProvider),
    );
    if (record == null || record.ownerId != owner) return null;
    if (record.name.trim().isEmpty || record.birthIso.isEmpty) return null;
    final birth = DateTime.tryParse(record.birthIso);
    if (birth == null) return null;
    return SoulMateDrawRequest(
      name: record.name,
      birthDate: birth,
      gender: switch (record.gender) {
        'feminine' => SoulMateGenderPref.feminine,
        'masculine' => SoulMateGenderPref.masculine,
        _ => null,
      },
      intention: record.intention,
    );
  }

  static String visibleMessage(SoulMateDrawResult result) {
    if (result.hasPortrait || result.declined) return '';
    return SoulMatePaidDraw.messageFor(result) ?? SoulMateCopy.unavailable;
  }
}
