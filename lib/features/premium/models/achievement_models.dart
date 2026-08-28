/// OR-1090 — Achievement system models (only unlockable keys).
library;

import 'package:flutter/material.dart';

enum AchievementId {
  firstReading('first_reading', 'İlk Açılım', 'İlk tarot açılımını tamamladın.'),
  cards100('cards_100', '100 Kart', '100 kart keşfettin.'),
  firstPremium('first_premium', 'İlk Premium', 'OR Premium ailesine katıldın.');

  const AchievementId(this.key, this.title, this.description);
  final String key;
  final String title;
  final String description;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.unlocked,
    required this.icon,
    required this.unlockedAt,
  });

  final AchievementId id;
  final bool unlocked;
  final IconData icon;
  final DateTime? unlockedAt;

  static const icons = {
    AchievementId.firstReading: Icons.auto_fix_high_rounded,
    AchievementId.cards100: Icons.style_rounded,
    AchievementId.firstPremium: Icons.workspace_premium_rounded,
  };
}

abstract final class AchievementCatalogue {
  AchievementCatalogue._();

  /// Defaults show nothing unlocked — no decorative fake badges.
  static List<Achievement> defaults({Set<String>? unlockedKeys}) {
    final keys = unlockedKeys ?? const <String>{};
    return AchievementId.values
        .map(
          (id) => Achievement(
            id: id,
            unlocked: keys.contains(id.key),
            icon: Achievement.icons[id]!,
            unlockedAt: keys.contains(id.key) ? DateTime(2026, 8, 1) : null,
          ),
        )
        .toList();
  }
}
