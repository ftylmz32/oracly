/// Compact zodiac chip — selected halo, others stay quiet.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../content/astrology/models/astrology_content.dart';
import 'astrology_reference_tokens.dart';
import 'astrology_zodiac_illustration.dart';

class AstrologyReferenceZodiacTab extends StatefulWidget {
  const AstrologyReferenceZodiacTab({
    super.key,
    required this.sign,
    required this.selected,
    required this.onTap,
  });

  final ZodiacSignContent sign;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<AstrologyReferenceZodiacTab> createState() =>
      _AstrologyReferenceZodiacTabState();
}

class _AstrologyReferenceZodiacTabState
    extends State<AstrologyReferenceZodiacTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final name = OraclyL10n.t('zodiac.${widget.sign.id}');
    return Semantics(
      selected: selected,
      button: true,
      label: name,
      child: OraclyPressable(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        borderRadius: AstrologyReferenceTokens.tabChipRadius,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _well(selected),
            const SizedBox(height: AstrologyReferenceTokens.tabLabelGap),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (selected
                      ? ReadingTypography.label
                      : ReadingTypography.micro)(
                color: selected
                    ? OraclyChrome.goldPrimary.withValues(alpha: 0.96)
                    : OraclyChrome.cream.withValues(alpha: 0.38),
              ).copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: selected ? 11 : 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _well(bool selected) {
    final circleSize = selected
        ? AstrologyReferenceTokens.tabCircleSelected
        : AstrologyReferenceTokens.tabCircle;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OraclyChrome.violet.withValues(alpha: _pressed ? 0.52 : 0.40),
                  OraclyChrome.deepNavy.withValues(alpha: 0.88),
                ],
              )
            : null,
        color: selected ? null : OraclyChrome.deepNavy.withValues(alpha: 0.28),
        border: Border.all(
          color: selected
              ? OraclyChrome.goldHighlight.withValues(alpha: 0.92)
              : OraclyChrome.goldMuted.withValues(alpha: 0.18),
          width: selected ? AppBorderWidth.thin : AppBorderWidth.hairline,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: OraclyChrome.goldHighlight.withValues(alpha: 0.48),
                  blurRadius: 14,
                ),
                BoxShadow(
                  color: OraclyChrome.violet.withValues(alpha: 0.34),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: selected ? (_pressed ? 0.97 : 1.0) : 0.94,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: ClipOval(
            child: Opacity(
              opacity: selected ? 1.0 : 0.48,
              child: AstrologyZodiacIllustration(
                signId: widget.sign.id,
                size: circleSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
