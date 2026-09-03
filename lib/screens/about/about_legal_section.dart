/// About — Privacy Policy / Terms entry points (public URLs when configured).
library;

import 'package:flutter/material.dart';

import '../../core/legal/legal_copy.dart';
import '../../core/legal/legal_document_kind.dart';
import '../../core/legal/legal_link_actions.dart';
import '../../core/legal/oracly_legal_urls.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/premium/presentation/widgets/settings_tiles.dart';

class AboutLegalSection extends StatelessWidget {
  const AboutLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(title: LegalCopy.section),
        SettingsNavTile(
          icon: Icons.policy_outlined,
          title: LegalCopy.privacyPolicy,
          subtitle: OraclyLegalUrls.hasPrivacyPolicy
              ? LegalCopy.opensExternally
              : LegalCopy.missingUrl,
          onTap: () => LegalLinkActions.openDocument(
            context,
            LegalDocumentKind.privacyPolicy,
          ),
        ),
        SettingsNavTile(
          icon: Icons.description_outlined,
          title: LegalCopy.termsOfUse,
          subtitle: OraclyLegalUrls.hasTermsOfUse
              ? LegalCopy.opensExternally
              : LegalCopy.missingUrl,
          onTap: () => LegalLinkActions.openDocument(
            context,
            LegalDocumentKind.termsOfUse,
          ),
        ),
        SizedBox(height: AppSpacing.md),
      ],
    );
  }
}