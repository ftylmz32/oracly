import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../features/premium/models/personalization_models.dart';
import '../../features/premium/presentation/widgets/premium_background.dart';
import '../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../shared/ui/oracly_permission_dialog.dart';
import '../../shared/widgets/oracly_skeleton_loader.dart';
import '../../core/navigation/oracly_navigation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/copy/resilience_copy.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PersonalizationSettings _settings = const PersonalizationSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(settingsServiceProvider).load();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _loading = false;
    });
  }

  Future<void> _save(PersonalizationSettings updated) async {
    await ref.read(settingsProvider.notifier).saveSettings(updated);
    if (!mounted) return;
    setState(() => _settings = updated);
  }

  Future<void> _pickParticles() async {
    final result = await showSettingsChoiceSheet<ParticleIntensity>(
      context: context,
      title: 'Parçacık Yoğunluğu',
      current: _settings.particleIntensity,
      options: const [
        (ParticleIntensity.low, 'Düşük'),
        (ParticleIntensity.medium, 'Orta'),
        (ParticleIntensity.high, 'Yüksek'),
      ],
    );
    if (result != null) {
      await _save(_settings.copyWith(particleIntensity: result));
    }
  }

  Future<void> _pickAiPersonality() async {
    final result = await showSettingsChoiceSheet<AiPersonality>(
      context: context,
      title: 'AI Kişiliği',
      current: _settings.aiPersonality,
      options: const [
        (AiPersonality.mystical, 'Mistik'),
        (AiPersonality.gentle, 'Nazik'),
        (AiPersonality.direct, 'Doğrudan'),
        (AiPersonality.poetic, 'Şiirsel'),
      ],
    );
    if (result != null) {
      await _save(_settings.copyWith(aiPersonality: result));
    }
  }

  Future<void> _pickTheme() async {
    final result = await showSettingsChoiceSheet<AppThemeMode>(
      context: context,
      title: 'Tema Seçimi',
      current: _settings.theme,
      options: const [
        (AppThemeMode.cosmic, 'Kozmik'),
        (AppThemeMode.amethyst, 'Ametist'),
        (AppThemeMode.midnight, 'Gece Yarısı'),
        (AppThemeMode.aurora, 'Aurora'),
      ],
    );
    if (result != null) await _save(_settings.copyWith(theme: result));
  }

  String _particleLabel(ParticleIntensity v) => switch (v) {
        ParticleIntensity.low => 'Düşük',
        ParticleIntensity.medium => 'Orta',
        ParticleIntensity.high => 'Yüksek',
      };

  String _aiLabel(AiPersonality v) => switch (v) {
        AiPersonality.mystical => 'Mistik',
        AiPersonality.gentle => 'Nazik',
        AiPersonality.direct => 'Doğrudan',
        AiPersonality.poetic => 'Şiirsel',
      };

  String _themeLabel(AppThemeMode v) => switch (v) {
        AppThemeMode.cosmic => 'Kozmik',
        AppThemeMode.amethyst => 'Ametist',
        AppThemeMode.midnight => 'Gece Yarısı',
        AppThemeMode.aurora => 'Aurora',
      };

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await OraclyPermissionDialog.notifications(context);
      if (granted != true) return;
    }
    await _save(_settings.copyWith(notificationsEnabled: value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: Text(
                  'Ayarlar',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: OraclySkeletonLoader(message: ResilienceCopy.settingsLoading),
                )
              else
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SettingsSectionHeader(title: 'Görünüm'),
                      SettingsToggleTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Görünüm',
                        subtitle: 'Karanlık mistik tema',
                        value: _settings.darkAppearance,
                        onChanged: (v) =>
                            _save(_settings.copyWith(darkAppearance: v)),
                      ),
                      SettingsChoiceTile(
                        icon: Icons.palette_outlined,
                        title: 'Tema Seçimi',
                        value: _themeLabel(_settings.theme),
                        onTap: _pickTheme,
                      ),
                      const SettingsSectionHeader(title: 'Bildirimler'),
                      SettingsToggleTile(
                        icon: Icons.notifications_outlined,
                        title: 'Bildirimler',
                        subtitle: 'İsteğe bağlı hatırlatmalar',
                        value: _settings.notificationsEnabled,
                        onChanged: _toggleNotifications,
                      ),
                      const SettingsSectionHeader(title: 'Deneyim'),
                      SettingsToggleTile(
                        icon: Icons.volume_up_outlined,
                        title: 'Ses',
                        subtitle: 'Ritüel ve ambient sesler',
                        value: _settings.soundEnabled,
                        onChanged: (v) =>
                            _save(_settings.copyWith(soundEnabled: v)),
                      ),
                      SettingsToggleTile(
                        icon: Icons.vibration_rounded,
                        title: 'Dokunsal Geri Bildirim',
                        subtitle: 'Kart seçimi ve açılım titreşimleri',
                        value: _settings.hapticEnabled,
                        onChanged: (v) {
                          if (v) HapticFeedback.lightImpact();
                          _save(_settings.copyWith(hapticEnabled: v));
                        },
                      ),
                      SettingsChoiceTile(
                        icon: Icons.blur_on_rounded,
                        title: 'Parçacık Yoğunluğu',
                        value: _particleLabel(_settings.particleIntensity),
                        onTap: _pickParticles,
                      ),
                      SettingsChoiceTile(
                        icon: Icons.psychology_alt_outlined,
                        title: 'AI Kişiliği',
                        value: _aiLabel(_settings.aiPersonality),
                        onTap: _pickAiPersonality,
                      ),
                      const SettingsSectionHeader(title: 'Hakkında'),
                      SettingsNavTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Hakkında',
                        subtitle: 'Sürüm ve misyon',
                        onTap: () => OraclyNavigationService.openAbout(context),
                      ),
                      const SettingsSectionHeader(title: 'Hesap & Gizlilik'),
                      SettingsNavTile(
                        icon: Icons.security_rounded,
                        title: 'Gizlilik',
                        subtitle: 'Verilerini kontrol et',
                        onTap: () =>
                            OraclyNavigationService.openPrivacy(context),
                      ),
                      SettingsNavTile(
                        icon: Icons.manage_accounts_rounded,
                        title: 'Hesap',
                        subtitle: 'Profil ve üyelik bilgileri',
                        onTap: () => OraclyNavigationService.openProfile(context),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
