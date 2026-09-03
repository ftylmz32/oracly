/// Optional expandable guided memory prompts.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_entry_context.dart';

class DreamEntryGuidedQuestions extends StatefulWidget {
  const DreamEntryGuidedQuestions({
    super.key,
    required this.answers,
    required this.onChanged,
  });

  final Map<DreamGuidedQuestionId, String> answers;
  final void Function(DreamGuidedQuestionId id, String value) onChanged;

  @override
  State<DreamEntryGuidedQuestions> createState() =>
      _DreamEntryGuidedQuestionsState();
}

class _DreamEntryGuidedQuestionsState extends State<DreamEntryGuidedQuestions> {
  DreamGuidedQuestionId? _expanded;
  final _controllers = <DreamGuidedQuestionId, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(DreamGuidedQuestionId id) {
    return _controllers.putIfAbsent(
      id,
      () => TextEditingController(text: widget.answers[id] ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final id in DreamGuidedQuestionId.values) {
      final controller = _controllerFor(id);
      final next = widget.answers[id] ?? '';
      if (controller.text != next) controller.text = next;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DreamCopy.guidedIntro} ✦',
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight.withValues(alpha: 0.82),
            fontSize: 11,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        for (final id in DreamGuidedQuestionId.values) ...[
          _GuidedRow(
            id: id,
            expanded: _expanded == id,
            controller: _controllerFor(id),
            onTap: () => setState(() {
              _expanded = _expanded == id ? null : id;
            }),
            onChanged: (value) => widget.onChanged(id, value),
          ),
          SizedBox(height: AppSpacing.s4),
        ],
      ],
    );
  }
}

class _GuidedRow extends StatelessWidget {
  const _GuidedRow({
    required this.id,
    required this.expanded,
    required this.controller,
    required this.onTap,
    required this.onChanged,
  });

  final DreamGuidedQuestionId id;
  final bool expanded;
  final TextEditingController controller;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasAnswer = controller.text.trim().isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: hasAnswer ? 0.28 : 0.12),
        ),
      ),
      child: Column(
        children: [
          OraclyPressable(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    DreamEntryContext.guidedIcon(id),
                    size: 18,
                    color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DreamEntryContext.guidedLabel(id),
                      style: ReadingTypography.bodySmall(
                        color: OraclyChrome.cream.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.chevron_right,
                    color: OraclyChrome.cream.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: 2,
                style: ReadingTypography.bodySmall(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: DreamCopy.narrativeHint,
                  hintStyle: ReadingTypography.micro(color: AppColors.textHint),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: OraclyChrome.gold.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
