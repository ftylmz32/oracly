import 'package:flutter/material.dart';

import '../core/design_system/premium_cards/premium_info_card.dart';
import '../models/memory_item.dart';

/// Memory summary — delegates to [PremiumInfoCard].
class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.memories});

  final List<MemoryItem> memories;

  @override
  Widget build(BuildContext context) {
    final hasMemory = memories.isNotEmpty;
    final countLabel = '${memories.length} hafıza';

    return PremiumInfoCard(
      icon: Icons.psychology_rounded,
      title: 'Hafıza',
      badge: countLabel,
      body: hasMemory
          ? memories.first.content
          : 'Seni tanımaya yeni başlıyorum.',
    );
  }
}
