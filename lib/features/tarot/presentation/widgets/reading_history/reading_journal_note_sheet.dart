/// OR-437 — Optional private reflection after a reading.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/session_ending_copy.dart';
import '../../../../../core/copy/transparency_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/oracly_button.dart';

/// Opens a premium bottom sheet for a short personal journal note.
Future<String?> showReadingJournalNoteSheet({
  required BuildContext context,
  String? initialNote,
  String cardName = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ReadingJournalNoteSheet(
      initialNote: initialNote,
      cardName: cardName,
    ),
  );
}

class _ReadingJournalNoteSheet extends StatefulWidget {
  const _ReadingJournalNoteSheet({
    this.initialNote,
    this.cardName = '',
  });

  final String? initialNote;
  final String cardName;

  @override
  State<_ReadingJournalNoteSheet> createState() =>
      _ReadingJournalNoteSheetState();
}

class _ReadingJournalNoteSheetState extends State<_ReadingJournalNoteSheet> {
  late final TextEditingController _note;
  static const _maxLength = 280;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceElevated.withValues(alpha: 0.98),
              AppColors.surface.withValues(alpha: 0.96),
            ],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.28),
            width: AppBorderWidth.hairline,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.round,
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Kişisel Yansıma',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  widget.cardName.isEmpty
                      ? 'Bu an senin için ne ifade ediyor?'
                      : '${widget.cardName} — bu an senin için ne ifade ediyor?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  TransparencyCopy.journalPrivacy,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _note,
                  maxLines: 4,
                  maxLength: _maxLength,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.55,
                  ),
                  decoration: InputDecoration(
                    hintText: SessionEndingCopy.noteHint,
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      height: 1.45,
                    ),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.md,
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.22),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.md,
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.22),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.md,
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.48),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OraclyButton(
                        text: SessionEndingCopy.noteDismiss,
                        type: OraclyButtonType.ghost,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OraclyButton(
                        text: 'Kaydet',
                        onPressed: () =>
                            Navigator.pop(context, _note.text.trim()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
