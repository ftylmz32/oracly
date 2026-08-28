/// EPIC-025 — Floating bottom navigation — premium glass chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/design_system/app_layout.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/navigation/immersive/immersive_motion.dart';
import 'oracly_bottom_bar_chrome.dart';
import 'oracly_bottom_bar_item.dart';

/// Compact celestial nav — gold selected, muted inactive.
class OraclyBottomBar extends ConsumerStatefulWidget {
  const OraclyBottomBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double barHeight = AppLayout.navBarHeight;
  static const double horizontalMargin = AppLayout.navBarMarginH;
  static const double bottomMargin = AppLayout.navBarMarginBottom;

  static double totalHeight(BuildContext context) =>
      AppLayout.floatingNavClearance(context);

  @override
  ConsumerState<OraclyBottomBar> createState() => _OraclyBottomBarState();
}

class _OraclyBottomBarState extends ConsumerState<OraclyBottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _indicator;
  late Animation<double> _indicatorIndex;
  double _displayIndex = 0;

  @override
  void initState() {
    super.initState();
    _displayIndex = widget.currentIndex.toDouble();
    _indicator = AnimationController(
      vsync: this,
      duration: ImmersiveMotion.navSelect,
    );
    _indicatorIndex = AlwaysStoppedAnimation(_displayIndex);
  }

  @override
  void didUpdateWidget(covariant OraclyBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    _indicatorIndex = Tween<double>(
      begin: _displayIndex,
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _indicator,
      curve: ImmersiveMotion.pageEnterCurve,
    ));
    _indicator.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _displayIndex = widget.currentIndex.toDouble();
    });
  }

  @override
  void dispose() {
    _indicator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang =
        AppLocale.normalize(ref.watch(appLocaleProvider).languageCode);
    final destinations = oraclyBottomNavDestinations(lang);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        OraclyBottomBar.horizontalMargin,
        0,
        OraclyBottomBar.horizontalMargin,
        OraclyBottomBar.bottomMargin + bottomInset,
      ),
      child: DecoratedBox(
        decoration: OraclyBottomBarChrome.bar(brightness),
        child: SizedBox(
          height: OraclyBottomBar.barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final n = destinations.length;
              final itemWidth = constraints.maxWidth / n;
              final inset = AppLayout.navItemInset;
              return AnimatedBuilder(
                animation: _indicatorIndex,
                builder: (context, _) {
                  final left = itemWidth * _indicatorIndex.value + inset;
                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: inset,
                        bottom: inset,
                        width: itemWidth - inset * 2,
                        child: const OraclyBottomNavActivePill(),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < n; i++)
                            Expanded(
                              child: OraclyBottomNavItem(
                                data: destinations[i],
                                selected: widget.currentIndex == i,
                                onTap: () =>
                                    widget.onDestinationSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
