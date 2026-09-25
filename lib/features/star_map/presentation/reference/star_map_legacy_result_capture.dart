/// Soft-fail legacy leaf capture before opening a StarMap result.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/l10n/l10n.dart';
import '../../artifacts/yildizname_artifact_providers.dart';
import '../../artifacts/yildizname_legacy_section_kind.dart';
import '../../models/star_map_reading.dart';
import 'star_map_result_section.dart';

typedef StarMapLegacyCaptureIds = ({String? artifactId, DateTime? createdAt});

abstract final class StarMapLegacyResultCapture {
  StarMapLegacyResultCapture._();

  static Future<StarMapLegacyCaptureIds> tryCapture(
    BuildContext context, {
    required String title,
    required List<StarMapResultSection> sections,
    required YildiznameLegacySectionKind sectionKind,
    List<StarMapPlanetInfluence> planets = const [],
  }) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final ownerId = container
          .read(localStorageProvider)
          .getString(UserLocalDataIsolation.ownerKey)
          ?.trim();
      if (ownerId == null || ownerId.isEmpty) {
        return (artifactId: null, createdAt: null);
      }
      final now = DateTime.now().toUtc();
      final captured = await container
          .read(yildiznameLegacyCaptureServiceProvider)
          .captureLeaf(
            ownerId: ownerId,
            title: title,
            sections: sections,
            sectionKind: sectionKind,
            locale: OraclyL10n.code,
            planets: planets,
            dayKey:
                '${now.year.toString().padLeft(4, '0')}-'
                '${now.month.toString().padLeft(2, '0')}-'
                '${now.day.toString().padLeft(2, '0')}',
          );
      return (artifactId: captured?.id, createdAt: captured?.createdAtUtc);
    } catch (_) {
      return (artifactId: null, createdAt: null);
    }
  }
}
