/// Opens Yıldızname journal rows — exact artifact when present.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../star_map/artifacts/yildizname_artifact_navigation.dart';
import '../../star_map/artifacts/yildizname_artifact_providers.dart';

abstract final class DiscoveryJournalStarMapOpen {
  DiscoveryJournalStarMapOpen._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    String entryId,
  ) async {
    try {
      final artifact = await ref
          .read(yildiznameArtifactRepositoryProvider)
          .getById(entryId);
      if (artifact != null && context.mounted) {
        await YildiznameArtifactNavigation.open(context, artifact);
        return;
      }
    } catch (_) {}
    if (!context.mounted) return;
    // Old BirthChartRecord id — hub only.
    OraclyNavigationService.openStarMap(context);
  }
}
