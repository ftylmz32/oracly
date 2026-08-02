import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/tarot/screens/tarot_select_screen.dart';
import '../../../screens/ai/chat_screen.dart';
import '../../../screens/memory/memory_screen.dart';
import '../../../screens/profile/profile_screen.dart';
import '../../../screens/settings/settings_screen.dart';
import 'quick_action_card.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature yakında eklenecek 🚀'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: AppSpacing.md,
          ),
          child: Text(
            'Hızlı erişim',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1.4,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.02,
          children: [
            QuickActionCard(
              icon: Icons.auto_awesome,
              title: 'Tarot',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TarotSelectScreen(),
                  ),
                );
              },
            ),
            QuickActionCard(
              icon: Icons.nightlight_round,
              title: 'Astroloji',
              onTap: () => _comingSoon(context, 'Astroloji'),
            ),
            QuickActionCard(
              icon: Icons.psychology,
              title: 'Hafıza',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemoryScreen(),
                  ),
                );
              },
            ),
            QuickActionCard(
              icon: Icons.smart_toy,
              title: 'AI Sohbet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(),
                  ),
                );
              },
            ),
            QuickActionCard(
              icon: Icons.person,
              title: 'Profil',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
            QuickActionCard(
              icon: Icons.settings,
              title: 'Ayarlar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
