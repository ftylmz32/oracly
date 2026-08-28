/// Canonical top app bar — leading · TITLE · trailing (reference chrome).
library;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'app_icons.dart';
import 'app_layout.dart';
import 'oracly_app_bar_title.dart';
import 'oracly_chrome.dart';
import 'oracly_crystal_capsule.dart';
import 'oracly_header_action.dart';

/// Matches approved reference: circular action · engraved title · gem capsule.
class OraclyAppBar extends StatelessWidget {
  const OraclyAppBar({
    super.key,
    required this.title,
    this.titleChild,
    this.leading,
    this.trailing,
    this.onLeadingTap,
    this.leadingIcon = AppIcons.back,
    this.leadingLabel,
    this.titleIcon,
    this.titleIconSize = OraclyChrome.titleMarkSize,
    this.gemCount,
    this.onPremiumTap,
    this.height = OraclyChrome.headerHeight,
  });

  final String title;
  final Widget? titleChild;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onLeadingTap;
  final IconData leadingIcon;
  final String? leadingLabel;
  final IconData? titleIcon;
  final double titleIconSize;
  final String? gemCount;
  final VoidCallback? onPremiumTap;
  final double height;

  /// Menu · TITLE · crystal — feature hubs (Astrology, Dream, …).
  factory OraclyAppBar.menu({
    Key? key,
    required String title,
    VoidCallback? onMenuTap,
    String? gemCount,
    VoidCallback? onPremiumTap,
  }) {
    return OraclyAppBar(
      key: key,
      title: title,
      leadingIcon: Icons.menu_rounded,
      leadingLabel: OraclyL10n.t('nav.menu'),
      onLeadingTap: onMenuTap,
      gemCount: gemCount,
      onPremiumTap: onPremiumTap,
    );
  }

  /// Back · TITLE · crystal — pushed screens (Profile, Settings, …).
  factory OraclyAppBar.back({
    Key? key,
    required String title,
    VoidCallback? onBack,
    String? gemCount,
    VoidCallback? onPremiumTap,
  }) {
    return OraclyAppBar(
      key: key,
      title: title,
      leadingIcon: AppIcons.back,
      leadingLabel: OraclyL10n.t(L10nKeys.back),
      onLeadingTap: onBack,
      gemCount: gemCount,
      onPremiumTap: onPremiumTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLeadingLabel =
        leadingLabel ?? OraclyL10n.t(L10nKeys.back);
    final left = leading ??
        OraclyHeaderAction(
          icon: leadingIcon,
          label: resolvedLeadingLabel,
          onTap: onLeadingTap ??
              () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).maybePop();
                }
              },
        );

    final right = trailing ??
        (gemCount != null
            ? OraclyCrystalCapsule(
                count: gemCount!,
                onTap: onPremiumTap,
              )
            : const SizedBox.shrink());

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: AppLayout.headerSideMinWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: left),
            ),
          ),
          Expanded(
            child: OraclyAppBarTitle(
              title: title,
              titleChild: titleChild,
              titleIcon: titleIcon,
              titleIconSize: titleIconSize,
            ),
          ),
          SizedBox(
            width: AppLayout.headerSideMinWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
