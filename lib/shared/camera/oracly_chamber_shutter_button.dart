/// Gold shutter — quiet capture affordance for chamber camera.
library;

import 'package:flutter/material.dart';

import '../../core/accessibility/oracly_a11y.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/l10n/l10n.dart';

class OraclyChamberShutterButton extends StatelessWidget {
  const OraclyChamberShutterButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = OraclyL10n.t('a11y.capture');
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: OraclyA11y.ensureMinTouch(
            child: Ink(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: OraclyChrome.gold.withValues(
                    alpha: enabled ? OraclyA11y.goldOnDark : 0.40,
                  ),
                  width: 2.2,
                ),
                color: OraclyChrome.cream.withValues(
                  alpha: enabled ? 0.14 : 0.06,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
