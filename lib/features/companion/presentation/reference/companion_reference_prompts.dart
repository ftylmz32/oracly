/// Optional human starters — compact grid with inline expand.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';
import 'companion_prompt_invitation.dart';
import 'companion_reference_tokens.dart';

export 'companion_prompt_invitation.dart'
    show CompanionPromptChip, CompanionPromptInvitation;

class CompanionReferencePrompts extends StatefulWidget {
  const CompanionReferencePrompts({
    super.key,
    required this.onSelected,
    this.limit,
    this.recessed = false,
    this.kindId,
    this.light = false,
    this.collapsible = false,
    this.initialVisible = 4,
  });

  final ValueChanged<String> onSelected;
  final int? limit;
  final bool recessed;
  final String? kindId;
  final bool light;
  final bool collapsible;
  final int initialVisible;

  @override
  State<CompanionReferencePrompts> createState() =>
      _CompanionReferencePromptsState();
}

class _CompanionReferencePromptsState extends State<CompanionReferencePrompts> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all =
        CompanionCopy.suggestionsForKind(widget.kindId).take(widget.limit ?? 7);
    final items = all.toList();
    final cap = widget.collapsible && !_expanded
        ? widget.initialVisible.clamp(1, items.length)
        : items.length;
    final visible = items.take(cap).toList();
    final hidden = items.length - visible.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final gap = CompanionReferenceTokens.promptGap;
        final half = (maxWidth - gap) / 2;
        final twoCol = maxWidth >= 300 && !widget.light;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in visible)
                  SizedBox(
                    width: twoCol &&
                            !CompanionPromptInvitation.spansFullWidth(item)
                        ? half
                        : maxWidth,
                    child: CompanionPromptInvitation(
                      label: item,
                      recessed: widget.recessed,
                      light: widget.light,
                      onTap: () => widget.onSelected(item),
                    ),
                  ),
              ],
            ),
            if (widget.collapsible && hidden > 0 && !_expanded) ...[
              SizedBox(height: gap),
              _ShowMoreChip(
                label: CompanionCopy.plusLabel,
                onTap: () => setState(() => _expanded = true),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShowMoreChip extends StatelessWidget {
  const _ShowMoreChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: CompanionCopy.plusSemantics,
      child: OraclyPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: ReadingTypography.micro(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: OraclyChrome.goldLight.withValues(alpha: 0.50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
