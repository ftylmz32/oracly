/// Tarot archive empty — one human sentence + clear first draw.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../shared/widgets/oracly_empty_state.dart';

class ReadingHistoryEmptyState extends StatelessWidget {
  const ReadingHistoryEmptyState({
    super.key,
    this.onStartReading,
  });

  final VoidCallback? onStartReading;

  @override
  Widget build(BuildContext context) {
    return OraclyEmptyState(
      kind: OraclyLoadingKind.tarot,
      imageAsset: AppAssets.tarotHero,
      message: OraclyL10n.t('tarot.empty.history'),
      ctaLabel: onStartReading != null
          ? OraclyL10n.t('tarot.empty.history_cta')
          : null,
      onCta: onStartReading,
    );
  }
}
