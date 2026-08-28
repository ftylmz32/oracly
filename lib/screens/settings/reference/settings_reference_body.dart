/// Loaded Settings body — chrome, profile, live preference groups.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/resilience_copy.dart';
import '../../../core/design_system/app_layout.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../features/companion/models/or_chat_output_mode.dart';
import '../../../features/companion/services/companion_voice_conversation_access.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../shared/widgets/oracly_skeleton_loader.dart';
import 'settings_reference_account.dart';
import 'settings_reference_pickers.dart';
import 'settings_reference_prefs.dart';
import 'settings_reference_profile_summary.dart';
import 'settings_reference_tokens.dart';

class SettingsReferenceBody extends StatelessWidget {
  const SettingsReferenceBody({
    super.key,
    required this.loading,
    required this.settings,
    required this.languageCode,
    required this.profileName,
    required this.profilePremium,
    this.profilePhoto,
    required this.onSave,
  });

  final bool loading;
  final PersonalizationSettings settings;
  final String languageCode;
  final String profileName;
  final bool profilePremium;
  final ImageProvider? profilePhoto;
  final Future<void> Function(
    PersonalizationSettings Function(PersonalizationSettings),
  )
  onSave;

  Future<void> _apply<T>(
    BuildContext context,
    Future<T?> future,
    PersonalizationSettings Function(T) patch,
  ) async {
    final result = await future;
    if (result == null || !context.mounted) return;
    await onSave((_) => patch(result));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return OraclySkeletonLoader(message: ResilienceCopy.settingsLoading);
    }
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        SettingsReferenceTokens.screenHorizontal,
        SettingsReferenceTokens.headerToProfile,
        SettingsReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsReferenceProfileSummary(
                  name: profileName,
                  isPremium: profilePremium,
                  photo: profilePhoto,
                  subtitle: OraclyL10n.t(
                    profilePremium
                        ? L10nKeys.profilePremiumActive
                        : L10nKeys.profileManage,
                    languageCode: languageCode,
                  ),
                  emptyName: OraclyL10n.t(
                    L10nKeys.guestName,
                    languageCode: languageCode,
                  ),
                  languageCode: languageCode,
                  onTap: () => OraclyNavigationService.openProfile(context),
                ),
                SizedBox(height: SettingsReferenceTokens.profileToFirstSection),
                SettingsReferenceAccount(languageCode: languageCode),
                SizedBox(height: SettingsReferenceTokens.sectionGap),
                SettingsReferencePrefs(
                  settings: settings,
                  onSave: onSave,
                  onPickOrStyle: () => _apply(
                    context,
                    SettingsReferencePickers.personality(
                      context,
                      languageCode,
                      settings.aiPersonality,
                    ),
                    (v) => settings.copyWith(aiPersonality: v),
                  ),
                  onPickLanguage: () => _apply(
                    context,
                    SettingsReferencePickers.language(context, languageCode),
                    (v) => settings.copyWith(language: AppLocale.normalize(v)),
                  ),
                  onPickAppearance: () => _apply(
                    context,
                    SettingsReferencePickers.appearance(
                      context,
                      languageCode,
                      settings.appearanceMode,
                    ),
                    (v) => settings.copyWith(appearanceMode: v),
                  ),
                  onPickAtmosphere: () => _apply(
                    context,
                    SettingsReferencePickers.atmosphere(
                      context,
                      languageCode,
                      settings.atmosphereSign,
                    ),
                    (v) => settings.copyWith(atmosphereSign: v),
                  ),
                  onPickOutput: () async {
                    final next = await SettingsReferencePickers.output(
                      context,
                      languageCode,
                      OrChatOutputMode.fromStorage(settings.orOutputMode),
                    );
                    if (next == null || !context.mounted) return;
                    if (next.isConversation &&
                        !CompanionVoiceConversationAccess.ensure(context)) {
                      return;
                    }
                    await onSave(
                      (_) => settings.copyWith(orOutputMode: next.wire),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
