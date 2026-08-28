/// Progressive disclosure — preview stays readable; expand grows downward.
library;

import 'package:flutter/material.dart';

import '../../shared/widgets/oracly_pressable.dart';
import '../design_system/oracly_chrome.dart';
import '../theme/app_spacing.dart';
import '../theme/craftsmanship_rhythm.dart';
import '../theme/reading_flow_text.dart';
import '../theme/reading_typography.dart';
import 'reading_ux_copy.dart';

class ReadingExpandSection extends StatefulWidget {
  const ReadingExpandSection({
    super.key,
    required this.body,
    this.title,
    this.hero = false,
  });

  final String? title;
  final String body;
  final bool hero;

  static bool isLong(String body) {
    final text = body.trim();
    if (text.isEmpty) return false;
    final parts = ReadingFlowText.paragraphsOf(text);
    return parts.length > 2 || text.length > 360;
  }

  @override
  State<ReadingExpandSection> createState() => _ReadingExpandSectionState();
}

class _ReadingExpandSectionState extends State<ReadingExpandSection> {
  bool _open = false;
  final _anchor = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final text = widget.body.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final parts = ReadingFlowText.paragraphsOf(text);
    final collapse = ReadingExpandSection.isLong(text) && !_open;
    final shown = collapse ? parts.first : text;

    return Padding(
      key: _anchor,
      padding: EdgeInsets.only(
        bottom: widget.hero
            ? CraftsmanshipRhythm.betweenActs * 0.25
            : CraftsmanshipRhythm.betweenSections,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((widget.title ?? '').trim().isNotEmpty) ...[
            Text(
              widget.title!.trim(),
              style: ReadingTypography.sectionLabel(
                color: OraclyChrome.goldLight.withValues(alpha: 0.90),
              ),
            ),
            SizedBox(height: CraftsmanshipRhythm.afterTitle + AppSpacing.xs),
          ],
          ReadingFlowText(
            text: shown,
            emphasizeFirst: widget.hero && !collapse,
            style: widget.hero
                ? ReadingTypography.bodyCore(
                    color: OraclyChrome.cream.withValues(alpha: 0.96),
                  )
                : ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.90),
                  ),
          ),
          if (collapse) ...[
            SizedBox(height: CraftsmanshipRhythm.paragraphGap),
            _Continue(onTap: _expand),
          ],
        ],
      ),
    );
  }

  void _expand() {
    setState(() => _open = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _anchor.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top >= 0) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.06,
        duration: Duration.zero,
      );
    });
  }
}

class _Continue extends StatelessWidget {
  const _Continue({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            ReadingUxCopy.continueReading,
            style: ReadingTypography.footnote(
              color: OraclyChrome.goldLight.withValues(alpha: 0.88),
            ),
          ),
        ),
      ),
    );
  }
}
