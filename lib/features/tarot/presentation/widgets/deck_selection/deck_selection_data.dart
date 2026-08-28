/// OR-1020 — Sacred deck catalogue data.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../copy/tarot_l10n.dart';

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
    this.requiresPremium = false,
  });

  final String id;
  final String name;
  final String description;
  final int cardCount;
  final String energyTag;
  final IconData icon;
  final List<Color> artGradient;
  final Color accent;
  final bool requiresPremium;
}

/// One real deck. Unbuilt ids must not appear as usable distinct decks.
abstract final class TarotDeckCatalogue {
  TarotDeckCatalogue._();

  static const activeId = 'classic';
  static const canonicalDeckId = 'rider-waite';

  static const unbuiltIds = {
    'golden',
    'moon_oracle',
    'mystic_dreams',
    'ancient_wisdom',
    'future_visions',
  };

  static List<TarotDeckOption> get decks => [
        TarotDeckOption(
          id: activeId,
          name: TarotL10n.deckName,
          description: TarotL10n.deckDescription,
          cardCount: 78,
          energyTag: TarotL10n.deckTag,
          icon: Icons.auto_stories_rounded,
          artGradient: const [
            Color(0xFF3D2866),
            Color(0xFF2A1847),
            Color(0xFF140A24),
          ],
          accent: AppColors.purpleLight,
        ),
      ];

  static bool isSelectable(String id) => decks.any((d) => d.id == id);

  static bool isUnbuilt(String id) => unbuiltIds.contains(id);
}
