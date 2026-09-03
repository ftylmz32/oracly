/// Archive menu — brass icon well, label, chevron. Not instrument glass.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'star_map_reference_card_shell.dart';
import 'star_map_reference_tokens.dart';

class StarMapReferenceMenuItem {
  const StarMapReferenceMenuItem({
    required this.title,
    required this.icon,
    this.subtitle,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback onTap;
}

class StarMapReferenceMenuCards extends StatelessWidget {
  const StarMapReferenceMenuCards({super.key, required this.items});

  final List<StarMapReferenceMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: StarMapReferenceTokens.menuCardGap),
          _MenuCard(item: items[i]),
        ],
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final StarMapReferenceMenuItem item;

  @override
  Widget build(BuildContext context) {
    final brass = StarMapReferenceTokens.brassGlow;
    return StarMapReferenceCardShell(
      borderRadius: StarMapReferenceTokens.menuCardRadius,
      padding: StarMapReferenceTokens.menuCardPadding,
      elevated: true,
      onTap: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: StarMapReferenceTokens.menuCardHeight - 12,
        ),
        child: Row(
          children: [
            _BrassIconWell(icon: item.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: OraclyChrome.cream.withValues(alpha: 0.92),
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle!,
                      style: OraclyChrome.bodySecondary(size: 10).copyWith(
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: brass.withValues(alpha: 0.70),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrassIconWell extends StatelessWidget {
  const _BrassIconWell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brass = StarMapReferenceTokens.brassGlow;
    final candle = StarMapReferenceTokens.candleAmber;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            candle.withValues(alpha: 0.18),
            StarMapReferenceTokens.archiveInk.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(
          color: brass.withValues(alpha: 0.42),
          width: 0.85,
        ),
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          size: 18,
          color: brass.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
