/// Optional human starters — horizontal chips or compact wrap.
library;

import 'package:flutter/material.dart';

import '../../copy/companion_copy.dart';
import 'companion_prompt_invitation.dart';
import 'companion_prompt_show_more.dart';
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
    this.horizontal = false,
  });

  final ValueChanged<String> onSelected;
  final int? limit;
  final bool recessed;
  final String? kindId;
  final bool light;
  final bool collapsible;
  final int initialVisible;
  final bool horizontal;

  @override
  State<CompanionReferencePrompts> createState() =>
      _CompanionReferencePromptsState();
}

class _CompanionReferencePromptsState extends State<CompanionReferencePrompts> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = CompanionCopy.suggestionsForKind(
      widget.kindId,
    ).take(widget.limit ?? 7);
    final items = all.toList();
    final cap = widget.collapsible && !_expanded
        ? widget.initialVisible.clamp(1, items.length)
        : items.length;
    final visible = items.take(cap).toList();
    final hidden = items.length - visible.length;

    if (widget.horizontal) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final showAll = constraints.maxWidth >= 400 && visible.length == 3;
          final itemWidth = showAll
              ? (constraints.maxWidth -
                        CompanionReferenceTokens.promptGap *
                            (visible.length - 1)) /
                    visible.length
              : 168.0;
          return SizedBox(
            height: CompanionReferenceTokens.quickPromptCardHeight,
            child: Stack(
              children: [
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(width: CompanionReferenceTokens.promptGap),
                  itemBuilder: (context, i) {
                    final item = visible[i];
                    return SizedBox(
                      width: itemWidth,
                      child: CompanionPromptInvitation(
                        label: item,
                        recessed: widget.recessed,
                        light: widget.light,
                        horizontalChip: true,
                        iconIndex: i,
                        onTap: () => widget.onSelected(item),
                      ),
                    );
                  },
                ),
                if (!showAll && visible.length > 2)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 28,
                        alignment: Alignment.centerRight,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFF08050D)],
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFFD9B765),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

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
                    width:
                        twoCol &&
                            !CompanionPromptInvitation.spansFullWidth(item)
                        ? half
                        : maxWidth,
                    child: CompanionPromptInvitation(
                      label: item,
                      recessed: widget.recessed,
                      light: widget.light,
                      iconIndex: visible.indexOf(item),
                      onTap: () => widget.onSelected(item),
                    ),
                  ),
              ],
            ),
            if (widget.collapsible && hidden > 0 && !_expanded) ...[
              SizedBox(height: gap),
              CompanionPromptShowMore(
                onTap: () => setState(() => _expanded = true),
              ),
            ],
          ],
        );
      },
    );
  }
}
