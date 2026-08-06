/// OR-1020 — Sacred deck catalogue data.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// A selectable tarot or oracle deck in the ritual catalogue.
@immutable
class TarotDeckOption {
  const TarotDeckOption({
    required this.id,
    required this.name,
    required this.description,
    required this.cardCount,
    required this.energyTag,
    required this.icon,
    required this.artGradient,
    required this.accent,
  });

  final String id;
  final String name;
  final String description;
  final int cardCount;
  final String energyTag;
  final IconData icon;
  final List<Color> artGradient;
  final Color accent;
}

abstract final class TarotDeckCatalogue {
  TarotDeckCatalogue._();

  static const List<TarotDeckOption> decks = [
    TarotDeckOption(
      id: 'classic',
      name: 'Klasik Tarot',
      description:
          'Geleneksel Rider-Waite sembolleriyle evrenin kadim dilini oku.',
      cardCount: 78,
      energyTag: 'Sezgi',
      icon: Icons.auto_stories_rounded,
      artGradient: [Color(0xFF3D2866), Color(0xFF2A1847), Color(0xFF140A24)],
      accent: AppColors.purpleLight,
    ),
    TarotDeckOption(
      id: 'golden',
      name: 'Altın Tarot',
      description:
          'Altın ışıltılı kartlarla bolluk, güç ve ilahi rehberliği çağır.',
      cardCount: 78,
      energyTag: 'Bolluk',
      icon: Icons.workspace_premium_rounded,
      artGradient: [Color(0xFF0A0810), Color(0xFF1A1408), Color(0xFF3D2E0A)],
      accent: AppColors.goldLight,
    ),
    TarotDeckOption(
      id: 'moon_oracle',
      name: 'Ay Kehaneti',
      description:
          'Ay döngüleriyle sezgisel mesajlar al; gecenin bilgeliğini dinle.',
      cardCount: 44,
      energyTag: 'Ay Enerjisi',
      icon: Icons.nightlight_round,
      artGradient: [Color(0xFF6B4BC4), Color(0xFF3D2566), Color(0xFF12071F)],
      accent: AppColors.purpleLight,
    ),
    TarotDeckOption(
      id: 'mystic_dreams',
      name: 'Mistik Rüyalar',
      description:
          'Rüya aleminin sembolleriyle bilinçaltının fısıltılarını çöz.',
      cardCount: 52,
      energyTag: 'Rüya',
      icon: Icons.cloud_rounded,
      artGradient: [Color(0xFF5E3A8C), Color(0xFF9B6DFF), Color(0xFF23153C)],
      accent: AppColors.purple,
    ),
    TarotDeckOption(
      id: 'ancient_wisdom',
      name: 'Kadim Bilgelik',
      description:
          'Kadim bilgelik taşıyan sembollerle köklerine ve karmana bağlan.',
      cardCount: 78,
      energyTag: 'Bilgelik',
      icon: Icons.account_balance_rounded,
      artGradient: [Color(0xFF3A2558), Color(0xFF8B6914), Color(0xFF1C1030)],
      accent: AppColors.gold,
    ),
    TarotDeckOption(
      id: 'future_visions',
      name: 'Gelecek Vizyonları',
      description:
          'Geleceğin olası yollarını aydınlatan vizyoner bir deste keşfet.',
      cardCount: 60,
      energyTag: 'Vizyon',
      icon: Icons.visibility_rounded,
      artGradient: [Color(0xFF7B4FD4), Color(0xFF2A6B8C), Color(0xFF0F0820)],
      accent: Color(0xFF7EC8E3),
    ),
  ];
}
