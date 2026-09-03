/// Explicit save / unsave — never automatic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/favorite_moments_copy.dart';
import '../../models/favorite_moment.dart';
import '../../providers/favorite_moments_providers.dart';

class SaveFavoriteMomentLink extends ConsumerWidget {
  const SaveFavoriteMomentLink({
    super.key,
    required this.draft,
    this.align = Alignment.center,
    this.prepare,
  });

  final FavoriteMoment draft;
  final Alignment align;
  final Future<FavoriteMoment?> Function()? prepare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoriteMomentSavedProvider(draft.id));
    final label =
        saved ? FavoriteMomentsCopy.unsave : FavoriteMomentsCopy.save;
    return Align(
      alignment: align,
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        button: true,
        label: label,
        child: OraclyPressable(
          onTap: saved
              ? () => _unsave(context, ref)
              : () => _save(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_add_outlined,
                    size: 16,
                    color: OraclyChrome.goldLight.withValues(
                      alpha: saved ? 0.92 : 0.78,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: ReadingTypography.footnote(
                      color: OraclyChrome.goldLight.withValues(
                        alpha: saved ? 0.88 : 0.82,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    var moment = draft;
    if (prepare != null) {
      final prepared = await prepare!();
      if (prepared == null) return;
      moment = prepared;
    }
    await ref.read(favoriteMomentsProvider.notifier).save(moment);
    if (!context.mounted) return;
    OraclySnackBar.success(context, FavoriteMomentsCopy.saved);
  }

  Future<void> _unsave(BuildContext context, WidgetRef ref) async {
    await ref.read(favoriteMomentsProvider.notifier).remove(draft.id);
    if (!context.mounted) return;
    OraclySnackBar.show(context, message: FavoriteMomentsCopy.removed);
  }
}
