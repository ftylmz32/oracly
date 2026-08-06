/// SPRINT-001 — Tag input with suggestions.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/dream_copy.dart';
import 'dream_section_header.dart';

class DreamTagInput extends StatefulWidget {
  const DreamTagInput({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  static const suggestions = [
    'gece',
    'tekrarlayan',
    'net',
    'bulanık',
    'uçma',
    'düşme',
  ];

  @override
  State<DreamTagInput> createState() => _DreamTagInputState();
}

class _DreamTagInputState extends State<DreamTagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase();
    if (tag.isEmpty || widget.tags.contains(tag)) return;
    widget.onChanged([...widget.tags, tag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DreamCopy.tagsLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          onSubmitted: _addTag,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: DreamCopy.tagHint,
            hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.55),
            border: OutlineInputBorder(borderRadius: AppRadius.md),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.md,
              borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.22)),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addTag(_controller.text),
            ),
          ),
        ),
        if (widget.tags.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in widget.tags)
                DreamChip(
                  label: tag,
                  selected: true,
                  onTap: () => _removeTag(tag),
                ),
            ],
          ),
        ],
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final suggestion in DreamTagInput.suggestions)
              if (!widget.tags.contains(suggestion))
                DreamChip(
                  label: suggestion,
                  onTap: () => _addTag(suggestion),
                ),
          ],
        ),
      ],
    );
  }
}
