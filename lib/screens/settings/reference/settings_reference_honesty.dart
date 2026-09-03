/// Settings footer — keep only live destinations.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/legal/legal_copy.dart';
import '../../../core/legal/legal_document_kind.dart';
import '../../../core/legal/legal_link_actions.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import 'settings_reference_group.dart';

class SettingsReferenceHonesty extends StatelessWidget {
  const SettingsReferenceHonesty({super.key, required this.languageCode});

  final String languageCode;

  String _t(String key) => OraclyL10n.t(key, languageCode: languageCode);

  @override
  Widget build(BuildContext context) {
    return SettingsReferenceGroup(
      title: _t(L10nKeys.sectionAbout),
      rows: [
        SettingsReferenceRow(
          icon: Icons.help_outline_rounded,
          title: _t(L10nKeys.help),
          subtitle: _t(L10nKeys.helpSubtitle),
          showChevron: true,
          onTap: () => OraclyNavigationService.openHelp(context),
        ),
        SettingsReferenceRow(
          icon: Icons.info_outline_rounded,
          title: _t(L10nKeys.about),
          subtitle: _t(L10nKeys.aboutSubtitle),
          showChevron: true,
          onTap: () => OraclyNavigationService.openAbout(context),
        ),
        SettingsReferenceRow(
          icon: Icons.policy_outlined,
          title: LegalCopy.privacyPolicy,
          subtitle: LegalCopy.opensExternally,
          showChevron: true,
          onTap: () => LegalLinkActions.openDocument(
            context,
            LegalDocumentKind.privacyPolicy,
          ),
        ),
        SettingsReferenceRow(
          icon: Icons.description_outlined,
          title: LegalCopy.termsOfUse,
          subtitle: LegalCopy.opensExternally,
          showChevron: true,
          onTap: () => LegalLinkActions.openDocument(
            context,
            LegalDocumentKind.termsOfUse,
          ),
        ),
      ],
    );
  }
}
