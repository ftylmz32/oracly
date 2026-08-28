/// Personal daily line — opens today's reserved note.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/copy/first_session_copy.dart';
import '../../../core/copy/home_personal_copy.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';

class HomeTodayMoment extends ConsumerWidget {
  const HomeTodayMoment({super.key});

  static String get label => OraclyL10n.t('home.today_moment');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = ref.watch(isFirstSessionProvider).valueOrNull ?? false;
    final observation = ref.watch(oraclyObservationProvider('home'));
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();

    final observed = observation?.line.trim() ?? '';
    final line = observed.isNotEmpty
        ? observed
        : first
            ? FirstSessionCopy.homeSubtitleNew
            : HomePersonalCopy.ritualWelcome(universe.ritualTime);

    final compact = MediaQuery.sizeOf(context).height < 720;
    final lineMax = compact ? 1 : 2;

    return Semantics(
      button: true,
      label: '$label. $line',
      child: OraclyPressable(
        onTap: () => OraclyNavigationService.openDailyMessage(context),
        child: Padding(
          padding: const EdgeInsets.only(left: 2, right: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: ReadingTypography.eyebrow(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.90),
                  fontSize: 11,
                ).copyWith(
                  letterSpacing: CraftsmanshipRhythm.sectionLabelTracking + 0.2,
                ),
              ),
              SizedBox(height: compact ? 3 : 5),
              Text(
                line,
                maxLines: lineMax,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.bodyCore(
                  color: OraclyChrome.cream.withValues(alpha: 0.90),
                ).copyWith(fontSize: compact ? 12.5 : 13.5, height: 1.38),
              ),
              SizedBox(height: compact ? 3 : 5),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: LinearGradient(
                    colors: [
                      OraclyChrome.gold.withValues(alpha: 0.34),
                      OraclyChrome.violet.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const SizedBox(width: 44, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
