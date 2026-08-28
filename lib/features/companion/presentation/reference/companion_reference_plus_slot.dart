/// Extra action entry — opens real starters, never a dead tap.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_tokens.dart';

class CompanionReferencePlusSlot extends StatelessWidget {
  const CompanionReferencePlusSlot({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = CompanionReferenceTokens.composerControl;
    final active = onTap != null;
    return Semantics(
      button: true,
      enabled: active,
      label: CompanionCopy.plusSemantics,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OraclyChrome.cardSurface.withValues(
                alpha: active ? 0.30 : 0.18,
              ),
              border: Border.all(
                color: OraclyChrome.gold.withValues(
                  alpha: active ? 0.22 : 0.12,
                ),
                width: 0.65,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: OraclyChrome.goldLight.withValues(
                alpha: active ? 0.82 : 0.38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
