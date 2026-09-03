/// Premium dream input card with subtle voice action.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_entry_context.dart';

class DreamEntryInputCard extends StatelessWidget {
  const DreamEntryInputCard({
    super.key,
    required this.controller,
    required this.onVoiceTap,
    this.voiceEnabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onVoiceTap;
  final bool voiceEnabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final count = controller.text.length;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: OraclyChrome.cardSurface.withValues(alpha: 0.22),
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: 0.16),
              width: 0.6,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✦ ${DreamCopy.inputPrompt}',
                            style: ReadingTypography.sectionLabel(
                              color: OraclyChrome.goldLight.withValues(alpha: 0.86),
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: AppSpacing.s4),
                          Text(
                            DreamCopy.inputSupport,
                            style: ReadingTypography.bodySmall(
                              color: OraclyChrome.cream.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (voiceEnabled)
                      Semantics(
                        button: true,
                        label: DreamCopy.voiceLabel,
                        child: IconButton(
                          onPressed: onVoiceTap,
                          icon: Icon(
                            Icons.mic_none_rounded,
                            color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  minLines: 4,
                  maxLength: DreamEntryContext.narrativeMaxLength,
                  style: ReadingTypography.body(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: DreamCopy.inputHint,
                    hintStyle: ReadingTypography.bodySmall(
                      color: AppColors.textHint,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: OraclyChrome.gold.withValues(alpha: 0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: OraclyChrome.gold.withValues(alpha: 0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: OraclyChrome.gold.withValues(alpha: 0.42),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    DreamCopy.charLimit(count),
                    style: ReadingTypography.micro(
                      color: OraclyChrome.cream.withValues(alpha: 0.48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
