/// Compact Dream landing hub — write, voice, recent analyses.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../models/dream.dart';
import 'dream_reference_action_buttons.dart';
import 'dream_reference_app_bar.dart';
import 'dream_reference_illustration_card.dart';
import 'dream_reference_intro.dart';
import 'dream_reference_recent_list.dart';
import 'dream_reference_tokens.dart';

class DreamReferenceEntryHub extends StatelessWidget {
  const DreamReferenceEntryHub({
    super.key,
    required this.dreams,
    required this.onWriteTap,
    required this.onVoiceTap,
    required this.onDreamTap,
  });

  final List<Dream> dreams;
  final VoidCallback onWriteTap;
  final VoidCallback onVoiceTap;
  final ValueChanged<Dream> onDreamTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DreamReferenceTokens.screenHorizontal,
        DreamReferenceTokens.screenTop,
        DreamReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout =
                  DreamReferenceTokens.layoutFor(constraints.maxHeight);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DreamReferenceAppBar(),
                  SizedBox(height: layout.gap),
                  const DreamReferenceIntro(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, mid) {
                        final maxH = mid.maxHeight;
                        if (!(maxH > 0)) return const SizedBox.shrink();
                        final h = layout.heroHeight.clamp(0.0, maxH);
                        return Align(
                          alignment: const Alignment(0, -0.08),
                          child: DreamReferenceIllustrationCard(height: h),
                        );
                      },
                    ),
                  ),
                  DreamReferenceActionButtons(
                    onWriteTap: onWriteTap,
                    onVoiceTap: onVoiceTap,
                    voiceEnabled: true,
                  ),
                  SizedBox(height: layout.gap),
                  DreamReferenceRecentList(
                    dreams: dreams,
                    onDreamTap: onDreamTap,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
