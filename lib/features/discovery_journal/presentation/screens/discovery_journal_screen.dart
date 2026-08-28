/// Keşif Günlüğü — timeline of real persisted experiences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/continuation/models/session_continuation.dart';
import '../../../../core/continuation/services/session_continuation_focus_store.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../gems/widgets/oracly_live_gem_capsule.dart';
import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../copy/discovery_journal_copy.dart';
import '../../providers/discovery_journal_providers.dart';
import '../widgets/discovery_journal_atmosphere.dart';
import '../widgets/discovery_journal_empty.dart';
import '../widgets/discovery_journal_timeline.dart';

class DiscoveryJournalScreen extends ConsumerWidget {
  const DiscoveryJournalScreen({super.key});

  String? _consumeFocusTheme(WidgetRef ref) {
    final storage = ref.read(localStorageProvider);
    return SessionContinuationFocusStore(storage)
        .consumeFor(SessionContinuationTarget.discoveryJournal)
        ?.theme;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(discoveryJournalEntriesProvider);
    final focusTheme = _consumeFocusTheme(ref);
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
                title: DiscoveryJournalCopy.screenTitle,
                titleIcon: Icons.auto_stories_rounded,
                onLeadingTap: () => Navigator.of(context).maybePop(),
                trailing: const OraclyLiveGemCapsule(),
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
                DiscoveryJournalCopy.subtitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.62),
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const OraclyCinematicLoading(compact: true),
                error: (_, _) => OraclyErrorState(
                  kind: OraclyLoadingKind.chamber,
                  title: ResilienceCopy.historyLoadFailedTitle,
                  message: ResilienceCopy.historyLoadFailed,
                  onRetry: () =>
                      ref.invalidate(discoveryJournalEntriesProvider),
                ),
                data: (items) => items.isEmpty
                    ? const DiscoveryJournalEmpty()
                    : DiscoveryJournalTimeline(
                        items: items,
                        focusTheme: focusTheme,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
