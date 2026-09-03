/// Settings content switch — loading, error, or live body.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/resilience_copy.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../shared/widgets/oracly_error_state.dart';
import 'settings_reference_body.dart';

class SettingsReferenceContent extends StatelessWidget {
  const SettingsReferenceContent({
    super.key,
    required this.loading,
    required this.loadFailed,
    required this.settings,
    required this.languageCode,
    required this.profileName,
    required this.profilePremium,
    required this.profilePhoto,
    required this.onRetry,
    required this.onSave,
  });

  final bool loading;
  final bool loadFailed;
  final PersonalizationSettings settings;
  final String languageCode;
  final String profileName;
  final bool profilePremium;
  final ImageProvider? profilePhoto;
  final VoidCallback onRetry;
  final Future<void> Function(
    PersonalizationSettings Function(PersonalizationSettings),
  )
  onSave;

  @override
  Widget build(BuildContext context) {
    if (loadFailed) {
      return OraclyErrorState(
        title: ResilienceCopy.errorTitle,
        message: ResilienceCopy.settingsLoadFailed,
        onRetry: onRetry,
      );
    }
    return SettingsReferenceBody(
      loading: loading,
      settings: settings,
      languageCode: languageCode,
      profileName: profileName,
      profilePremium: profilePremium,
      profilePhoto: profilePhoto,
      onSave: onSave,
    );
  }
}
