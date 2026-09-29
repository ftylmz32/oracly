/// Explicit save / unsave — never automatic.
///
/// [SaveFavoriteMomentLink.forensicLegacyRow] is test-only. Frozen 7A–7C
/// goldens keep the pre-P4C row. Live production stays on the responsive wrap.
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
    this.forensicLegacyRow = false,
  });

  final FavoriteMoment draft;
  final Alignment align;
  final Future<FavoriteMoment?> Function()? prepare;

  /// Frozen historical chrome only. Production default is the wrap.
  final bool forensicLegacyRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoriteMomentSavedProvider(draft.id));
    final label = saved ? FavoriteMomentsCopy.unsave : FavoriteMomentsCopy.save;
    return Align(
      alignment: align,
      widthFactor: 1,
      heightFactor: 1,
      child: OraclyPressable(
        label: label,
        onTap: saved ? () => _unsave(context, ref) : () => _save(context, ref),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ExcludeSemantics(
              child: _FavoriteLinkChrome(
                forensicLegacyRow: forensicLegacyRow,
                icon: Icon(
                  saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                  size: 16,
                  color: OraclyChrome.goldLight.withValues(
                    alpha: saved ? 0.92 : 0.78,
                  ),
                ),
                label: Text(
                  label,
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.goldLight.withValues(
                      alpha: saved ? 0.88 : 0.82,
                    ),
                  ),
                ),
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

/// Shared glyph. Only the row versus wrap container differs.
class _FavoriteLinkChrome extends StatelessWidget {
  const _FavoriteLinkChrome({
    required this.forensicLegacyRow,
    required this.icon,
    required this.label,
  });

  final bool forensicLegacyRow;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    if (forensicLegacyRow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 6), label],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [icon, label],
    );
  }
}
