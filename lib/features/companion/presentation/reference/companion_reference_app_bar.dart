/// OR header — quiet chrome · official brand mark · presence.
///
/// Conversation space stays dominant; mark stays compact.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_menu_sheet.dart';
import 'companion_or_presence.dart';
import 'companion_reference_identity.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceAppBar extends StatelessWidget {
  const CompanionReferenceAppBar({
    super.key,
    this.onBack,
    this.onPremiumTap,
    this.speaking = false,
    this.presence,
  });

  final VoidCallback? onBack;
  final VoidCallback? onPremiumTap;
  final bool speaking;
  final CompanionOrPresence? presence;

  static String get title => CompanionCopy.screenTitle;

  @override
  Widget build(BuildContext context) {
    final back = onBack != null;
    return SizedBox(
      height: CompanionReferenceTokens.headerHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          OraclyAppBar(
            title: CompanionCopy.screenTitle,
            height: CompanionReferenceTokens.headerHeight,
            titleChild: CompanionReferenceIdentity(
              speaking: speaking,
              presence: presence,
            ),
            leadingIcon: back ? AppIcons.back : Icons.menu_rounded,
            leadingLabel:
                back ? OraclyL10n.t(L10nKeys.back) : OraclyL10n.t('nav.menu'),
            onLeadingTap: onBack ??
                () => showCompanionOrMenu(
                      context,
                      onPremiumTap: onPremiumTap,
                    ),
            trailing: OraclyLiveGemCapsule(
              onTap: onPremiumTap ??
                  () => OraclyNavigationService.openGems(context),
            ),
          ),
        ],
      ),
    );
  }
}
