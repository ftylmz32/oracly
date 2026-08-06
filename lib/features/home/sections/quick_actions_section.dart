import 'package:flutter/material.dart';

import '../../../screens/memory/memory_screen.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../widgets/quick_action_tile.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 18),
            child: Text(
              'Explore',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                letterSpacing: 2.0,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.32,
            children: [
              QuickActionTile(
                phase: 0,
                icon: Icons.style_rounded,
                title: 'Tarot',
                onTap: () =>
                    OraclyNavigation.switchToTab(context, OraclyTab.tarot),
              ),
              QuickActionTile(
                phase: 1,
                icon: Icons.nightlight_round,
                title: 'Dream Analysis',
                onTap: () =>
                    OraclyNavigation.switchToTab(context, OraclyTab.chat),
              ),
              QuickActionTile(
                phase: 2,
                icon: Icons.auto_awesome,
                title: 'Astrology',
                onTap: () =>
                    OraclyNavigation.switchToTab(context, OraclyTab.chat),
              ),
              QuickActionTile(
                phase: 3,
                icon: Icons.smart_toy_rounded,
                title: 'AI Companion',
                onTap: () =>
                    OraclyNavigation.switchToTab(context, OraclyTab.chat),
              ),
              QuickActionTile(
                phase: 4,
                icon: Icons.menu_book_rounded,
                title: 'Journal',
                onTap: () =>
                    OraclyNavigation.switchToTab(context, OraclyTab.chat),
              ),
              QuickActionTile(
                phase: 5,
                icon: Icons.psychology_rounded,
                title: 'Memory',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemoryScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
