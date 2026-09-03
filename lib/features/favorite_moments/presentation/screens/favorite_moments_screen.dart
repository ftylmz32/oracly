/// Favori Anlarım — personal collection of saved moment fragments.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../discovery_journal/presentation/widgets/discovery_archive_heading.dart';
import '../../../discovery_journal/presentation/widgets/discovery_journal_atmosphere.dart';
import '../../../discovery_journal/presentation/widgets/discovery_journal_spine.dart';
import '../../copy/favorite_moments_copy.dart';
import '../../providers/favorite_moments_providers.dart';
import '../../services/favorite_moment_opener.dart';
import '../widgets/favorite_moment_tile.dart';
import '../widgets/favorite_moments_empty.dart';

class FavoriteMomentsScreen extends ConsumerWidget {
  const FavoriteMomentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteMomentsProvider);
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const DiscoveryJournalAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                OraclyChrome.screenSide,
                OraclyChrome.screenTop,
                OraclyChrome.screenSide,
                0,
              ),
              child: OraclyAppBar(
                title: FavoriteMomentsCopy.title,
                titleIcon: Icons.bookmarks_rounded,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                OraclyChrome.screenSide,
                AppSpacing.s8,
                OraclyChrome.screenSide,
                0,
              ),
              child: Text(
                FavoriteMomentsCopy.subtitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.62),
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const OraclyCinematicLoading(compact: true),
                error: (_, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: OraclyChrome.screenSide,
                    ),
                    child: OraclyErrorState(
                      title: ResilienceCopy.errorTitle,
                      message: ResilienceCopy.temporaryFailure,
                      onRetry: () => ref.invalidate(favoriteMomentsProvider),
                    ),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? const FavoriteMomentsEmpty()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          OraclyChrome.screenSide,
                          AppSpacing.lg,
                          OraclyChrome.screenSide,
                          AppLayout.scrollBottomInset(context),
                        ),
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return DiscoveryArchiveHeading(
                              label: FavoriteMomentsCopy.title,
                              top: 0,
                            );
                          }
                          final i = index - 1;
                          final moment = items[i];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.s12,
                            ),
                            child: DiscoveryJournalSpine(
                              isFirst: i == 0,
                              isLast: i == items.length - 1,
                              child: FavoriteMomentTile(
                                moment: moment,
                                onTap: () => FavoriteMomentOpener.open(
                                  context,
                                  ref,
                                  moment,
                                ),
                                onRemove: () async {
                                  await ref
                                      .read(favoriteMomentsProvider.notifier)
                                      .remove(moment.id);
                                  if (!context.mounted) return;
                                  OraclySnackBar.show(
                                    context,
                                    message: FavoriteMomentsCopy.removed,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
