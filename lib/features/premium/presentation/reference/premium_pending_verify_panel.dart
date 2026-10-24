/// Shown while a paid store proof awaits a definitive verdict. It sells
/// nothing: no plans, prices or purchase button, so no second charge can
/// start. It never says the payment was collected and grants no access.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class PremiumPendingVerifyPanel extends StatelessWidget {
  const PremiumPendingVerifyPanel({
    super.key,
    required this.checking,
    required this.onCheck,
  });

  /// A status check started by the user is running.
  final bool checking;

  /// Null while the store sheet itself is still open: there is no held
  /// receipt to check yet.
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final body = OraclyChrome.cream.withValues(alpha: 0.9);
    // Separate nodes: the title is a heading, the body is read as text and
    // the check is its own focusable button, not one merged block.
    return Semantics(
      container: true,
      liveRegion: true,
      explicitChildNodes: true,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0A14).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: OraclyChrome.goldLight.withValues(alpha: 0.45),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 22,
                    color: OraclyChrome.goldLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      PremiumCopy.pendingVerifyTitle,
                      style: ReadingTypography.body(
                        color: OraclyChrome.goldLight,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              PremiumCopy.pendingVerifyBody,
              style: ReadingTypography.body(color: body),
            ),
            const SizedBox(height: 8),
            Text(
              PremiumCopy.pendingVerifyAccess,
              style: ReadingTypography.secondary(
                color: OraclyChrome.cream.withValues(alpha: 0.78),
              ),
            ),
            if (onCheck != null) ...[
              const SizedBox(height: 16),
              _CheckButton(
                label: checking
                    ? PremiumCopy.pendingVerifyChecking
                    : PremiumCopy.pendingVerifyCheck,
                onTap: checking ? null : onCheck,
              ),
            ],
            // A calm way out: plain back navigation only. It never buys,
            // restores, verifies, clears the saved proof or grants access;
            // the hold stays and greets the user again on return.
            if (Navigator.maybeOf(context)?.canPop() ?? false) ...[
              const SizedBox(height: 4),
              _LaterLink(onTap: () => Navigator.of(context).maybePop()),
            ],
          ],
        ),
      ),
    );
  }
}

/// Outlined status check. Its label may wrap to two lines at large text
/// instead of being cut off; disabled while a check runs.
class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final gold = OraclyChrome.goldLight.withValues(alpha: enabled ? 1 : 0.55);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: OraclyPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.body(
                    color: gold,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet exit styled like [OraclyQuietLink]. The label is announced once:
/// the shared link also exposes its visible text, so screen readers read
/// it twice.
class _LaterLink extends StatelessWidget {
  const _LaterLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      label: PremiumCopy.pendingVerifyLater,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: OraclyA11y.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                PremiumCopy.pendingVerifyLater,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.sectionLabel(fontSize: 12).copyWith(
                  letterSpacing: 1.6,
                  color: OraclyChrome.goldLight.withValues(
                    alpha: OraclyA11y.quietGoldMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
