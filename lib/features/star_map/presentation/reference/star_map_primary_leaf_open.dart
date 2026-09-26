/// Phase 8B — flag-aware primary archive leaf entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../features/birth_chart/models/birth_profile.dart';
import '../../models/star_map_reading.dart';
import '../../narrative/live/yildizname_live_orchestrator_providers.dart';
import '../../narrative/live/yildizname_live_plan.dart';
import '../../narrative/live/yildizname_narrative_live_gate.dart';
import 'star_map_narrative_live_screen.dart';

typedef StarMapLegacySkyOpener = void Function(
  BuildContext context,
  StarMapReading reading, {
  BirthProfile? profile,
});

abstract final class StarMapPrimaryLeafOpen {
  StarMapPrimaryLeafOpen._();

  static Future<void> open({
    required BuildContext context,
    required StarMapReading reading,
    required bool Function() isNavigating,
    required void Function(bool) setNavigating,
    required StarMapLegacySkyOpener openLegacySky,
    BirthProfile? profile,
  }) async {
    if (isNavigating()) return;
    if (!YildiznameNarrativeLiveGate.isEnabled) {
      openLegacySky(context, reading, profile: profile);
      return;
    }
    setNavigating(true);
    try {
      final orch = ProviderScope.containerOf(context, listen: false)
          .read(yildiznameLiveOrchestratorProvider);
      final plan = await orch.preflight(languageCode: OraclyL10n.depend(context));
      if (!context.mounted) return;
      if (plan.kind == YildiznameLivePlanKind.legacyLocal ||
          !plan.isNarrativeEligible) {
        setNavigating(false);
        openLegacySky(context, reading, profile: profile);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const StarMapNarrativeLiveScreen(),
        ),
      );
    } finally {
      setNavigating(false);
    }
  }
}
