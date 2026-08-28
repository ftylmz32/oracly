/// Tarot empty — atmospheric plate via shared OraclyEmptyState.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../shared/widgets/oracly_empty_state.dart';

class TarotEmptyState extends StatelessWidget {
  const TarotEmptyState({
    super.key,
    required this.title,
    required this.message,
    @Deprecated('Prefer atmospheric imageAsset path via OraclyEmptyState.')
    this.icon = Icons.auto_awesome_outlined,
    this.actionLabel,
    this.onAction,
    this.imageAsset = AppAssets.tarotHero,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return OraclyEmptyState(
      kind: OraclyLoadingKind.tarot,
      imageAsset: imageAsset,
      title: title,
      message: message,
      ctaLabel: actionLabel,
      onCta: onAction,
    );
  }
}
