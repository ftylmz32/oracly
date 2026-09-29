/// Reference-accurate Settings screen — live prefs only, honest unavailable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/backend_providers.dart' as backend;
import '../../../core/notifications/oracly_notification_providers.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/runtime/oracly_apply_outcome.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../features/home/reference/home_reference_background.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../features/premium/providers/premium_providers.dart';
import '../../profile/data/profile_photo_store.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import 'settings_reference_app_bar.dart';
import 'settings_reference_content.dart';
import 'settings_reference_load.dart';
import 'settings_reference_tokens.dart';

class SettingsReferenceScreen extends ConsumerStatefulWidget {
  const SettingsReferenceScreen({super.key});

  @override
  ConsumerState<SettingsReferenceScreen> createState() =>
      _SettingsReferenceScreenState();
}

class _SettingsReferenceScreenState
    extends ConsumerState<SettingsReferenceScreen> {
  PersonalizationSettings _settings = const PersonalizationSettings();
  bool _loading = true;
  bool _loadFailed = false;
  bool _hasLoadedOnce = false;
  String _profileName = '';
  Future<void> _write = Future.value();
  int _editGeneration = 0;
  int _settledGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    await loadSettingsReference(
      ref: ref,
      context: context,
      isMounted: () => mounted,
      hasLoadedOnce: _hasLoadedOnce,
      onLoaded: ({required settings, required profileName}) {
        setState(() {
          _settings = settings;
          _profileName = profileName;
          _loading = false;
          _loadFailed = false;
          _hasLoadedOnce = true;
        });
      },
      onFirstFailure: () => setState(() {
        _loading = false;
        _loadFailed = true;
      }),
      onCachedFailure: () => setState(() => _loading = false),
    );
  }

  Future<void> _save(PersonalizationSettings updated) {
    final previousNotify = _settings.notificationsEnabled;
    final notifyIntentChanged = updated.notificationsEnabled != previousNotify;
    final generation = ++_editGeneration;
    final intent = updated;
    _settings = intent;
    if (mounted) setState(() {});
    _write = _write.then((_) async {
      if (!mounted || generation != _editGeneration) return;
      try {
        final audioResult = await ref
            .read(settingsProvider.notifier)
            .saveSettings(intent);
        if (!mounted || generation != _editGeneration) return;
        var visible = intent;
        if (audioResult.settings != intent) {
          visible = audioResult.settings;
          setState(() => _settings = visible);
        }

        var notifyFailed = false;
        final notifyOutcome = await ref
            .read(oraclyNotificationCoordinatorProvider)
            .sync(visible);
        if (!mounted || generation != _editGeneration) return;
        // Only roll back the notifications flag when THIS save changed it.
        // Ambient/sound/language saves must not invert an unrelated toggle.
        if (notifyOutcome.isFailure && notifyIntentChanged) {
          notifyFailed = true;
          final corrected = visible.copyWith(
            notificationsEnabled: previousNotify,
          );
          await ref.read(settingsProvider.notifier).saveSettings(corrected);
          if (!mounted || generation != _editGeneration) return;
          visible = corrected;
          setState(() => _settings = corrected);
        } else if (notifyOutcome.isFailure) {
          notifyFailed = true;
        }

        _settledGeneration = generation;
        if (audioResult.hasFailure) {
          OraclySnackBar.show(
            context,
            message: ResilienceCopy.settingsAudioApplyFailed,
          );
        } else if (notifyFailed) {
          OraclySnackBar.show(
            context,
            message: ResilienceCopy.settingsNotificationApplyFailed,
          );
        }
      } catch (_) {
        if (!mounted || generation != _editGeneration) return;
        OraclySnackBar.show(
          context,
          message: ResilienceCopy.settingsSaveFailed,
        );
      }
    });
    return _write;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data == null || !mounted || _loadFailed) return;
      if (_editGeneration != _settledGeneration) return;
      setState(() {
        _settings = data;
        _loading = false;
        _hasLoadedOnce = true;
      });
    });
    ref.listen<int>(backend.localDataOwnerEpochProvider, (previous, next) {
      if (!mounted || previous == next) return;
      setState(() => _profileName = '');
      _load();
    });
    ref.watch(appLocaleProvider);
    ref.watch(appThemeModeProvider);
    final premiumStatus = ref.watch(premiumStatusProvider);
    final lang = AppLocale.normalize(_settings.language);
    return OraclyScaffold(
      usePremiumBackground: false,
      backgroundOverlay: const HomeReferenceBackground(
        child: SizedBox.shrink(),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              SettingsReferenceTokens.screenHorizontal,
              SettingsReferenceTokens.screenTop,
              SettingsReferenceTokens.screenHorizontal,
              0,
            ),
            child: SettingsReferenceAppBar(
              title: OraclyL10n.t(L10nKeys.settingsTitle, languageCode: lang),
              backLabel: OraclyL10n.t(L10nKeys.back, languageCode: lang),
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SettingsReferenceContent(
              loading: _loading,
              loadFailed: _loadFailed,
              settings: _settings.copyWith(language: lang),
              languageCode: lang,
              profileName: _profileName,
              profilePremium: premiumStatus.isPremium,
              premiumKnown: premiumStatus.loaded,
              profilePhoto: ref.watch(profilePhotoProvider),
              onRetry: _load,
              onSave: (patch) => _save(patch(_settings)),
            ),
          ),
        ],
      ),
    );
  }
}
