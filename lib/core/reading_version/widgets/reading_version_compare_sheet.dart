/// Side-by-side version compare — original vs active by default.
library;

import 'package:flutter/material.dart';

import '../../design_system/oracly_chrome.dart';
import '../../theme/app_spacing.dart';
import '../../theme/reading_typography.dart';
import '../copy/reading_version_copy.dart';
import '../models/reading_version_group.dart';
import '../models/reading_version_kind.dart';
import '../services/reading_version_payload.dart';

Future<void> showReadingVersionCompareSheet({
  required BuildContext context,
  required ReadingVersionGroup group,
  required String Function(Map<String, dynamic> data) preview,
}) {
  final original = group.originalEntry;
  final latest = group.entries.last;
  if (original == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: OraclyChrome.midnight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ReadingVersionCopy.compareTitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(
                  color: OraclyChrome.goldLight,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              _Column(
                title: ReadingVersionCopy.original,
                body: preview(original.data),
              ),
              const SizedBox(height: AppSpacing.s12),
              _Column(
                title: latest.isOriginal
                    ? ReadingVersionCopy.original
                    : ReadingVersionCopy.revision(latest.number),
                body: preview(latest.data),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Column extends StatelessWidget {
  const _Column({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: OraclyChrome.gold.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: ReadingTypography.sectionLabel(
                color: OraclyChrome.goldLight,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              body.trim().isEmpty ? '—' : body,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String readingVersionPreview(
  ReadingVersionKind kind,
  Map<String, dynamic> data,
) {
  return switch (kind) {
    ReadingVersionKind.tarot => ReadingVersionPayload.tarotSummary(data),
    ReadingVersionKind.dream => ReadingVersionPayload.dreamAnalysis(data),
    ReadingVersionKind.coffee ||
    ReadingVersionKind.palm =>
      ReadingVersionPayload.tarotSummary({'summary': data['overall'] ?? ''}),
  };
}

