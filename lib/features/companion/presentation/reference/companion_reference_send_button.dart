/// Send — gold circle with upward arrow when ready.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceSendButton extends StatelessWidget {
  const CompanionReferenceSendButton({
    super.key,
    required this.onTap,
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    final size = CompanionReferenceTokens.composerControl;
    return Semantics(
      button: true,
      enabled: active,
      label: CompanionCopy.sendLabel,
      child: OraclyPressable(
        onTap: active ? onTap : null,
        behavior: HitTestBehavior.opaque,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        OraclyChrome.goldLight.withValues(alpha: 0.98),
                        OraclyChrome.gold.withValues(alpha: 0.92),
                      ],
                    )
                  : null,
              color: active
                  ? null
                  : OraclyChrome.violet.withValues(alpha: 0.14),
              border: Border.all(
                color: OraclyChrome.gold.withValues(
                  alpha: active ? 0.55 : 0.18,
                ),
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: OraclyChrome.gold.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              size: 20,
              color: active
                  ? OraclyChrome.midnight
                  : OraclyChrome.goldLight.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
