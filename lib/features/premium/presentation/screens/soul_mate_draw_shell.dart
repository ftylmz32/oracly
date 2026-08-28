/// Shared Premium atmosphere + app bar for soul-mate draw.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../copy/soul_mate_copy.dart';
import '../reference/premium_reference_atmosphere.dart';
import '../reference/premium_reference_tokens.dart';

class SoulMateDrawShell extends StatelessWidget {
  const SoulMateDrawShell({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const PremiumReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                PremiumReferenceTokens.screenHorizontal,
                PremiumReferenceTokens.screenTop,
                PremiumReferenceTokens.screenHorizontal,
                0,
              ),
              child: OraclyAppBar(
                title: SoulMateCopy.screenTitle,
                onLeadingTap: () => Navigator.of(context).maybePop(),
                trailing: const OraclyLiveGemCapsule(),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
