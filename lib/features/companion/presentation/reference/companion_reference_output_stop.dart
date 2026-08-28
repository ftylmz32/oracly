/// Durdur control while OR is speaking in SESLİ mode.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';

abstract final class CompanionOutputModeTokens {
  CompanionOutputModeTokens._();

  /// Visual chip height — hit target padded to [OraclyA11y.minTouchTarget].
  static const double height = 32;
  static final BorderRadius radius = BorderRadius.circular(AppRadius.r16);
}

class CompanionReferenceOutputStop extends StatelessWidget {
  const CompanionReferenceOutputStop({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: CompanionCopy.stopSpeaking,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: CompanionOutputModeTokens.radius,
        child: OraclyA11y.ensureMinTouch(
          child: Container(
            height: CompanionOutputModeTokens.height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: CompanionOutputModeTokens.radius,
              color: OraclyChrome.midnight.withValues(alpha: 0.45),
              border: Border.all(
                color: OraclyChrome.gold.withValues(alpha: 0.32),
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stop_rounded,
                  size: 15,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                ),
                const SizedBox(width: 4),
                Text(
                  CompanionCopy.stopSpeaking,
                  style: AppTextStyles.caption.copyWith(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
