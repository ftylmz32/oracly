/// OR-404 — Intention topic catalogue for the ritual screen.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// One sacred intention the seeker may hold during the reading.
@immutable
class IntentionTopicOption {
  const IntentionTopicOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.glow,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color glow;
}

abstract final class IntentionTopicCatalogue {
  IntentionTopicCatalogue._();

  static const List<IntentionTopicOption> topics = [
    IntentionTopicOption(
      id: 'love',
      title: 'Aşk',
      subtitle: 'Kalp, bağ ve duygusal rehberlik',
      icon: Icons.favorite_rounded,
      accent: Color(0xFFE8A4C8),
      glow: Color(0x339B6DFF),
    ),
    IntentionTopicOption(
      id: 'career',
      title: 'Kariyer',
      subtitle: 'Yol, amaç ve profesyonel netlik',
      icon: Icons.work_outline_rounded,
      accent: AppColors.goldLight,
      glow: Color(0x33D4AF37),
    ),
    IntentionTopicOption(
      id: 'money',
      title: 'Para',
      subtitle: 'Bolluk, güven ve maddi denge',
      icon: Icons.payments_rounded,
      accent: Color(0xFF7EC8A3),
      glow: Color(0x335EE6A8),
    ),
    IntentionTopicOption(
      id: 'health',
      title: 'Sağlık',
      subtitle: 'Beden, enerji ve içsel denge',
      icon: Icons.healing_rounded,
      accent: Color(0xFF9BD4FF),
      glow: Color(0x336B9BFF),
    ),
    IntentionTopicOption(
      id: 'growth',
      title: 'Kişisel Gelişim',
      subtitle: 'Dönüşüm, bilgelik ve ruhsal büyüme',
      icon: Icons.self_improvement_rounded,
      accent: AppColors.purpleLight,
      glow: Color(0x339B6DFF),
    ),
  ];
}
