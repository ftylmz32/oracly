/// Reference discovery grid — Keşfet 3×2 core + Dream extension strip.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/universe/universe_map_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_reference_modules.dart';
import 'home_reference_module_tile.dart';
import 'home_reference_scope.dart';
import 'home_reference_tokens.dart';

class HomeReferenceModuleGrid extends ConsumerWidget {
  const HomeReferenceModuleGrid({super.key, this.layoutOverride});

  final HomeViewportLayout? layoutOverride;

  static const int columns = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = layoutOverride ?? HomeReferenceScope.maybeOf(context);
    final gap = layout?.moduleGap ?? 11;
    final tileH = (layout?.moduleTileHeight ?? 112)
        .clamp(HomeReferenceTokens.moduleTileMinHeight, 128.0);
    final dreamH = layout?.dreamExtensionHeight ?? 78;
    final first = ref.watch(isFirstSessionProvider).valueOrNull ?? false;
    final modules = HomeReferenceModules.list(quietPremium: first);
    final rows = (modules.length / columns).ceil();
    final band = OraclyL10n.t('home.discoveries_band');
    final seeAll = OraclyL10n.t('home.discoveries.see_all');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
          child: SizedBox(
            height: 22,
            child: Row(
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 15,
                  color: OraclyA11y.goldReadable(AppColors.goldLight),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    band,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.eyebrow(
                      color: OraclyA11y.goldReadable(AppColors.goldLight),
                      fontSize: 12,
                    ).copyWith(
                      height: 1.1,
                      letterSpacing:
                          CraftsmanshipRhythm.sectionLabelTracking + 0.25,
                    ),
                  ),
                ),
                OraclyPressable(
                  onTap: () => UniverseMapSheet.open(context),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      seeAll,
                      maxLines: 1,
                      style: ReadingTypography.metadata().copyWith(
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: OraclyA11y.goldReadable(AppColors.goldLight),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) SizedBox(height: gap),
          SizedBox(
            height: tileH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) SizedBox(width: gap),
                  Expanded(
                    child: _cell(modules, row * columns + col),
                  ),
                ],
              ],
            ),
          ),
        ],
        SizedBox(height: gap),
        SizedBox(
          height: dreamH,
          child: HomeReferenceModuleTile(
            spec: HomeReferenceModules.dreamExtension,
          ),
        ),
      ],
    );
  }

  Widget _cell(List<HomeReferenceModuleSpec> modules, int index) {
    if (index >= modules.length) return const SizedBox.shrink();
    return HomeReferenceModuleTile(spec: modules[index]);
  }
}
