/// Smart revisit sheet — optional, dismissible, never blocks.

library;



import 'package:flutter/material.dart';



import '../../../../../core/design_system/oracly_chrome.dart';

import '../../../../../core/theme/app_spacing.dart';

import '../../../../../core/theme/reading_typography.dart';

import '../../../../../shared/ui/oracly_bottom_sheet.dart';

import '../../../../../shared/widgets/oracly_pressable.dart';

import '../../../copy/tarot_revisit_copy.dart';

import '../../../revisit/tarot_revisit_context.dart';

import '../../../revisit/tarot_revisit_mode.dart';



typedef TarotRevisitAction = void Function(TarotRevisitMode mode);



class TarotRevisitSheet {

  TarotRevisitSheet._();



  static Future<void> show(

    BuildContext context, {

    required TarotRevisitContext revisit,

    required VoidCallback onNewSpread,

    required VoidCallback onOpenPrior,

    required TarotRevisitAction onDifferentAngle,

  }) {

    return OraclyBottomSheet.show<void>(

      context,

      title: TarotRevisitCopy.sheetTitle,

      child: Padding(

        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Text(

              TarotRevisitCopy.body,

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

            const SizedBox(height: AppSpacing.s16),

            _Action(

              label: TarotRevisitCopy.actionNewSpread,

              onTap: () {

                Navigator.of(context).pop();

                onNewSpread();

              },

            ),

            _Action(

              label: TarotRevisitCopy.actionOpenPrior,

              onTap: () {

                Navigator.of(context).pop();

                onOpenPrior();

              },

            ),

            _Action(

              label: TarotRevisitCopy.actionAngle,

              onTap: () {

                Navigator.of(context).pop();

                onDifferentAngle(TarotRevisitMode.differentAngle);

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

          constraints: const BoxConstraints(minHeight: 48),

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


