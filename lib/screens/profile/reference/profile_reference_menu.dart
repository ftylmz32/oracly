/// Profile destinations — four real rooms, never a dump.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../copy/profile_copy.dart';
import 'profile_reference_settings_section.dart';

List<ProfileReferenceSettingsItem> profileReferenceMenu({
  required BuildContext context,
  VoidCallback? onLogout,
}) {
  return [
    ProfileReferenceSettingsItem(
      icon: Icons.auto_stories_outlined,
      title: ProfileCopy.journalTitle,
      onTap: () => OraclyNavigationService.openDiscoveryJournal(context),
    ),
    ProfileReferenceSettingsItem(
      icon: Icons.forum_outlined,
      title: ProfileCopy.orTitle,
      onTap: () => OraclyNavigationService.openChat(context),
    ),
    ProfileReferenceSettingsItem(
      icon: Icons.wb_twilight_outlined,
      title: ProfileCopy.dailyMessageTitle,
      onTap: () => OraclyNavigationService.openDailyMessage(context),
    ),
    ProfileReferenceSettingsItem(
      icon: Icons.settings_outlined,
      title: ProfileCopy.settingsTitle,
      onTap: () => OraclyNavigationService.openSettings(context),
    ),
    if (onLogout != null)
      ProfileReferenceSettingsItem(
        icon: Icons.logout_rounded,
        title: ProfileCopy.logoutTitle,
        onTap: onLogout,
      ),
  ];
}
