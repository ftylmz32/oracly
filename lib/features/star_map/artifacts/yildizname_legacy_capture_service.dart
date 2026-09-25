/// Captures legacy StarMap leaf snapshots — soft-fails persistence.
library;

import 'package:flutter/foundation.dart';

import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_exceptions.dart';
import 'yildizname_artifact_factory.dart';
import 'yildizname_artifact_repository.dart';
import 'yildizname_legacy_section_kind.dart';

class YildiznameLegacyCaptureService {
  YildiznameLegacyCaptureService(this._repo);

  final YildiznameArtifactRepository _repo;

  /// Returns existing/new artifact, or null when persistence soft-fails.
  Future<YildiznameArtifact?> captureLeaf({
    required String ownerId,
    required String title,
    required List<StarMapResultSection> sections,
    required YildiznameLegacySectionKind sectionKind,
    required String locale,
    List<StarMapPlanetInfluence> planets = const [],
    String? sunSignId,
    String? dayKey,
    DateTime? createdAtUtc,
  }) async {
    try {
      final draft = YildiznameArtifactFactory.createLegacy(
        ownerId: ownerId,
        title: title,
        sections: sections,
        sectionKind: sectionKind,
        locale: locale,
        planets: planets,
        sunSignId: sunSignId,
        dayKey: dayKey,
        createdAtUtc: createdAtUtc,
      );
      for (final a in await _repo.getAll()) {
        if (a.semanticDedupeKey == draft.semanticDedupeKey) return a;
      }
      return await _repo.saveNew(draft);
    } on YildiznameArtifactOwnerUnavailableException {
      return null;
    } catch (e, st) {
      debugPrint('[YildiznameLegacyCapture] soft-fail: $e\n$st');
      return null;
    }
  }
}
