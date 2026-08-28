/// Smart revisit card in OR — topic + spread only, never dates.

library;



import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../core/design_system/oracly_chrome.dart';

import '../../../core/design_system/oracly_glass_card.dart';

import '../../../core/theme/app_spacing.dart';

import '../../../core/theme/reading_typography.dart';

import '../../../features/tarot/copy/tarot_revisit_copy.dart';

import '../../../features/tarot/revisit/tarot_revisit_context.dart';

import '../../../shared/widgets/oracly_pressable.dart';

import '../copy/discovery_revisit_copy.dart';

import '../providers/discovery_revisit_provider.dart';

import '../services/discovery_revisit_opener.dart';



class DiscoveryRevisitCard extends ConsumerWidget {

  const DiscoveryRevisitCard({super.key, required this.revisit});



  final TarotRevisitContext revisit;



  void _dismiss(WidgetRef ref) {

    ref.read(discoveryRevisitDismissedIdProvider.notifier).state =

        revisit.reading.id;

  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    return Padding(

      padding: const EdgeInsets.only(top: AppSpacing.s8),

      child: OraclyGlassCard(

        premium: true,

        borderRadius: OraclyChrome.heroRadius,

        padding: const EdgeInsets.all(AppSpacing.s16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Text(

              DiscoveryRevisitCopy.prompt,

              style: ReadingTypography.body(

                color: OraclyChrome.cream.withValues(alpha: 0.82),

              ),

            ),

            Padding(

              padding: const EdgeInsets.only(top: AppSpacing.s8),

              child: Text(

                TarotRevisitCopy.contextLine(revisit),

                style: ReadingTypography.footnote(

                  color: OraclyChrome.gold.withValues(alpha: 0.72),

                ),

              ),

            ),

            const SizedBox(height: AppSpacing.s12),

            _Action(

              label: DiscoveryRevisitCopy.newSpread,

              onTap: () {

                _dismiss(ref);

                DiscoveryRevisitOpener.newSpread(context);

              },

            ),

            _Action(

              label: DiscoveryRevisitCopy.openPrior,

              onTap: () {

                _dismiss(ref);

                DiscoveryRevisitOpener.openPrior(context, revisit);

              },

            ),

            _Action(

              label: DiscoveryRevisitCopy.newAngle,

              onTap: () {

                _dismiss(ref);

                DiscoveryRevisitOpener.newAngle(context, ref, revisit);

              },

            ),

          ],

        ),

      ),

    );

  }

}



class _Action extends StatelessWidget {

  const _Action({required this.label, required this.onTap});



  final String label;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: AppSpacing.s8),

      child: OraclyPressable(

        onTap: onTap,

        child: ConstrainedBox(

          constraints: const BoxConstraints(minHeight: 44),

          child: DecoratedBox(

            decoration: BoxDecoration(

              border: Border.all(

                color: OraclyChrome.gold.withValues(alpha: 0.28),

              ),

              borderRadius: BorderRadius.circular(14),

            ),

            child: Center(

              child: Text(

                label,

                style: ReadingTypography.sectionLabel(

                  color: OraclyChrome.goldLight,

                  fontSize: 12,

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }

}


