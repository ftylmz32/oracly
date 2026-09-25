/// Opens a stored Yıldızname artifact exactly — no regeneration.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_page_transitions.dart';
import '../presentation/reference/star_map_artifact_reopen_screen.dart';
import 'yildizname_artifact.dart';

abstract final class YildiznameArtifactNavigation {
  YildiznameArtifactNavigation._();

  static Future<void> open(
    BuildContext context,
    YildiznameArtifact artifact,
  ) {
    return Navigator.of(context).push<void>(
      OraclyPageTransitions.fade(
        page: StarMapArtifactReopenScreen(artifact: artifact),
      ),
    );
  }
}
