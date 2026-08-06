/// OR-1000 — Tarot section title component.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../theme/tarot_theme.dart';

/// Uppercase mystical section heading with optional trailing action.
class TarotSectionTitle extends StatelessWidget {
  const TarotSectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TarotTheme.sectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
