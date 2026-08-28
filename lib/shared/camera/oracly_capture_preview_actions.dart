/// Preview actions — use photo / retake / optional gallery. Never fake crop.
library;

import 'package:flutter/material.dart';

import '../../core/accessibility/oracly_a11y.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/theme/reading_typography.dart';
import '../widgets/oracly_gold_button.dart';
import '../widgets/oracly_quiet_link.dart';

class OraclyCapturePreviewActions extends StatelessWidget {
  const OraclyCapturePreviewActions({
    super.key,
    required this.useLabel,
    required this.retakeLabel,
    required this.onUse,
    required this.onRetake,
    this.galleryLabel,
    this.onGallery,
    this.hint,
  });

  final String useLabel;
  final String retakeLabel;
  final VoidCallback? onUse;
  final VoidCallback onRetake;
  final String? galleryLabel;
  final VoidCallback? onGallery;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OraclyGoldButton(label: useLabel, expanded: true, onPressed: onUse),
        const SizedBox(height: 10),
        OraclyQuietLink(label: retakeLabel, onTap: onRetake),
        if (galleryLabel != null && onGallery != null)
          OraclyQuietLink(label: galleryLabel!, onTap: onGallery!),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint!,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.footnote(
              color: OraclyChrome.goldLight.withValues(
                alpha: OraclyA11y.quietGold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
