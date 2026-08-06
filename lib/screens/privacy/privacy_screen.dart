/// EPIC-014 — Privacy controls with honest, calm communication.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/copy/transparency_copy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/memory_service.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';
import '../../shared/ui/oracly_snackbar.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryService = MemoryService();
    final storageService = StorageService();
    final profileService = ProfileService();
    final historyService = ref.read(historyServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik'),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          _IntroCard(text: TransparencyCopy.privacyIntro),
          SizedBox(height: AppSpacing.md),
          _PrivacyCard(
            icon: Icons.auto_stories_outlined,
            title: 'Tarot Günlüğünü Temizle',
            subtitle:
                'Kayıtlı açılımları ve kişisel notlarını sil — yalnızca bu cihazda',
            onTap: () async {
              await historyService.clear();
              if (!context.mounted) return;
              ref.invalidate(readingHistoryProvider);
              _showMessage(context, TransparencyCopy.journalCleared);
            },
          ),
          _PrivacyCard(
            icon: Icons.psychology,
            title: 'Hafızayı Temizle',
            subtitle: 'OR\'ın öğrendiği sohbet bağlamını sil',
            onTap: () async {
              await memoryService.clearMemory();
              if (!context.mounted) return;
              _showMessage(context, TransparencyCopy.memoryCleared);
            },
          ),
          _PrivacyCard(
            icon: Icons.history,
            title: 'Sohbet Geçmişini Temizle',
            subtitle: 'Tüm eski konuşmaları sil',
            onTap: () async {
              await storageService.clearMessages();
              if (!context.mounted) return;
              _showMessage(context, TransparencyCopy.chatHistoryCleared);
            },
          ),
          _PrivacyCard(
            icon: Icons.delete_forever,
            title: 'Tüm Verileri Sıfırla',
            subtitle:
                'Profil, hafıza, sohbet ve tarot günlüğünü tamamen sil',
            onTap: () async {
              await memoryService.clearMemory();
              await storageService.clearMessages();
              await profileService.clearProfile();
              await historyService.clear();
              if (!context.mounted) return;
              ref.invalidate(readingHistoryProvider);
              _showMessage(context, TransparencyCopy.allDataReset);
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    OraclySnackBar.show(context, message: message);
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceElevated.withValues(alpha: 0.6),
      child: Padding(
        padding: AppSpacing.card,
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
