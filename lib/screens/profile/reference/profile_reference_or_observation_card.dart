/// ORACLY observation — editorial insight; taps continue into OR.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../features/personal_discovery/models/oracly_observation.dart';
import '../../../features/personal_discovery/presentation/widgets/oracly_observation_surface.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../copy/profile_copy.dart';
import 'profile_chamber_chrome.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileReferenceOrObservationCard extends StatelessWidget {
  const ProfileReferenceOrObservationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return OraclyObservationSurface(
      surface: 'profile',
      builder: (context, OraclyObservation? observation) {
        if (observation == null) return const SizedBox.shrink();
        return OraclyPressable(
          onTap: () => OraclyNavigationService.openChat(
            context,
            readingContext: OracleReadingContextSources.discoveryJournal(
              id: 'profile_obs_${observation.theme.hashCode}',
              title: ProfileCopy.observationTitle,
              preview: observation.line,
              themes: [observation.theme],
              kindLabel: 'ORACLY',
            ),
          ),
          child: ProfileReferenceCardShell(
            weight: ProfileSurfaceWeight.highlight,
            glowStrength: 0.72,
            child: ProfileChamberRail(
              emphasis: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileChamberTitle(
                    title: ProfileCopy.observationTitle,
                    emphasis: true,
                  ),
                  SizedBox(height: ProfileChamberGap.afterTitle),
                  Text(
                    observation.line,
                    softWrap: true,
                    style: ReadingTypography.bodyCore(
                      color: OraclyChrome.cream.withValues(alpha: 0.92),
                    ),
                  ),
                  SizedBox(height: ProfileChamberGap.afterTitle),
                  Text(
                    ProfileCopy.newUserOrCta,
                    style: ReadingTypography.footnote(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
