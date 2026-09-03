/// Contextual module shortcuts -- circular gold line-art wells.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/modules/oracly_feature_id.dart';
import '../../../../core/modules/oracly_feature_navigation.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';
import 'companion_gold_line_icon.dart';
import 'companion_reference_tokens.dart';

class CompanionFeatureShortcuts extends StatelessWidget {
  const CompanionFeatureShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_Shortcut>[
      _Shortcut(
        OraclyFeatureId.tarot,
        CompanionLineIconKind.tarot,
        CompanionCopy.shortcutTarot,
      ),
      _Shortcut(
        OraclyFeatureId.coffee,
        CompanionLineIconKind.coffee,
        CompanionCopy.shortcutCoffee,
      ),
      _Shortcut(
        OraclyFeatureId.dream,
        CompanionLineIconKind.dream,
        CompanionCopy.shortcutDream,
      ),
      _Shortcut(
        OraclyFeatureId.astrology,
        CompanionLineIconKind.astrology,
        CompanionCopy.shortcutAstrology,
      ),
      _Shortcut(
        OraclyFeatureId.soulMate,
        CompanionLineIconKind.soulmate,
        CompanionCopy.shortcutSoulMate,
      ),
    ];
    final well = CompanionReferenceTokens.shortcutWellSize;
    return SizedBox(
      height: CompanionReferenceTokens.shortcutRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return OraclyPressable(
            onTap: () => OraclyFeatureNavigation.open(context, item.id),
            label: item.label,
            child: SizedBox(
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF14101C).withValues(alpha: 0.92),
                      border: Border.all(
                        color: OraclyChrome.gold.withValues(alpha: 0.52),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OraclyChrome.gold.withValues(alpha: 0.12),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: well,
                      height: well,
                      child: Center(
                        child: CompanionGoldLineIcon(
                          kind: item.icon,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.micro(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                    ).copyWith(fontSize: 10, letterSpacing: 0.15),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.id, this.icon, this.label);
  final OraclyFeatureId id;
  final CompanionLineIconKind icon;
  final String label;
}
