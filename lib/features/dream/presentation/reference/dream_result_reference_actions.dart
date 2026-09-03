/// Reference-aligned result actions — save, reinterpret.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../favorite_moments/copy/favorite_moments_copy.dart';
import '../../../favorite_moments/providers/favorite_moments_providers.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream.dart';

class DreamResultReferenceActions extends ConsumerWidget {
  const DreamResultReferenceActions({
    super.key,
    required this.dream,
    required this.analysis,
    this.onReinterpret,
  });

  final Dream dream;
  final String analysis;
  final Future<bool> Function()? onReinterpret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoriteMomentSavedProvider(dream.id));
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            label: saved
                ? FavoriteMomentsCopy.unsave
                : DreamCopy.resultSaveJournal,
            icon: Icons.bookmark_add_outlined,
            onTap: () => _toggleSave(context, ref, saved),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionChip(
            label: DreamCopy.resultReinterpret,
            icon: Icons.refresh_rounded,
            onTap: onReinterpret == null ? null : () => _reinterpret(context),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleSave(
    BuildContext context,
    WidgetRef ref,
    bool saved,
  ) async {
    if (saved) {
      await ref.read(favoriteMomentsProvider.notifier).remove(dream.id);
      if (!context.mounted) return;
      OraclySnackBar.show(context, message: FavoriteMomentsCopy.removed);
      return;
    }
    await ref.read(favoriteMomentsProvider.notifier).save(
          FavoriteMomentFactory.dream(
            id: dream.id,
            at: dream.recordedAt,
            narrative: dream.narrative,
            analysis: analysis,
          ),
        );
    if (!context.mounted) return;
    OraclySnackBar.success(context, FavoriteMomentsCopy.saved);
  }

  Future<void> _reinterpret(BuildContext context) async {
    final retry = onReinterpret;
    if (retry == null) return;
    try {
      await retry();
    } catch (_) {
      if (!context.mounted) return;
      OraclySnackBar.show(context, message: DreamCopy.analysisFailed);
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      enabled: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: onTap == null ? 0.1 : 0.22),
          ),
          color: Colors.black.withValues(alpha: 0.14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: OraclyChrome.goldLight.withValues(alpha: 0.76),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.cream.withValues(alpha: 0.84),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
