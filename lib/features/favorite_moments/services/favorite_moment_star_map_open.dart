/// Opens StarMap favorites — exact artifact when durable id is present.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../star_map/artifacts/yildizname_artifact_id.dart';
import '../../star_map/artifacts/yildizname_artifact_navigation.dart';
import '../../star_map/artifacts/yildizname_artifact_providers.dart';
import '../../star_map/artifacts/yildizname_artifact_reopen.dart';
import '../copy/favorite_moments_copy.dart';
import '../models/favorite_moment.dart';
import '../presentation/screens/favorite_moment_snapshot_screen.dart';
import 'favorite_moment_snapshot.dart';

abstract final class FavoriteMomentStarMapOpen {
  FavoriteMomentStarMapOpen._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    final sourceRef = moment.sourceRef.trim();
    if (YildiznameArtifactId.isValid(sourceRef)) {
      try {
        final artifact = await YildiznameArtifactReopen(
          ref.read(yildiznameArtifactRepositoryProvider),
        ).byId(sourceRef);
        if (artifact != null && context.mounted) {
          await YildiznameArtifactNavigation.open(context, artifact);
          return;
        }
      } catch (_) {}
      if (!context.mounted) return;
      await _fallbackOrUnavailable(context, moment);
      return;
    }
    // Old star-<hash> compatibility — hub only; never pretend exact artifact.
    OraclyNavigationService.openStarMap(context);
  }

  static Future<void> _fallbackOrUnavailable(
    BuildContext context,
    FavoriteMoment moment,
  ) async {
    if (!FavoriteMomentSnapshot.canShowFallback(moment)) {
      OraclySnackBar.show(
        context,
        message: FavoriteMomentsCopy.sourceUnavailable,
      );
      return;
    }
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: FavoriteMomentSnapshotScreen(moment: moment),
      ),
    );
  }
}
