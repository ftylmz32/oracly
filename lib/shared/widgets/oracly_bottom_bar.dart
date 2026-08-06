/// OR-005.2 / OR-024.2 — Premium bottom navigation for the Oracly shell.
library;

import 'package:flutter/material.dart';

import '../../core/navigation/universe/oracly_tab_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/oracly_brand_signature.dart';
import '../../shared/navigation/oracly_navigation.dart';
import 'oracly_pressable.dart';

/// Themed bottom navigation bar — use inside [OraclyAppShell].
class OraclyBottomBar extends StatelessWidget {
  const OraclyBottomBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Icon row + label fit inside this height (see [_NavDestination]).
  static const double _contentHeight = AppSpacing.xxl + AppSpacing.sm;

  static final _destinations = [
    _NavItemData(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: OraclyTab.home.universeLabel,
      hint: OraclyTab.home.universeHint,
    ),
    _NavItemData(
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
      label: OraclyTab.tarot.universeLabel,
      hint: OraclyTab.tarot.universeHint,
    ),
    _NavItemData(
      icon: Icons.smart_toy_outlined,
      selectedIcon: Icons.smart_toy,
      label: OraclyTab.chat.universeLabel,
      hint: OraclyTab.chat.universeHint,
    ),
    _NavItemData(
      icon: Icons.route_outlined,
      selectedIcon: Icons.route_rounded,
      label: OraclyTab.profile.universeLabel,
      hint: OraclyTab.profile.universeHint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(
            color: AppColors.matteBorder,
            width: AppBorderWidth.hairline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.32),
            blurRadius: AppShadowMetrics.softBlur,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: SizedBox(
            height: _contentHeight,
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavDestination(
                      data: _destinations[i],
                      selected: currentIndex == i,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.hint,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? hint;
}

class _NavDestination extends StatefulWidget {
  const _NavDestination({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  static const double _iconSlotHeight = AppSpacing.lg + AppSpacing.sm;
  static const double _labelGap = AppSpacing.xs / 2;
  static const double _labelFontSize = 11;

  @override
  State<_NavDestination> createState() => _NavDestinationState();
}

class _NavDestinationState extends State<_NavDestination> {
  void _handleTap() {
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: _handleTap,
      scale: !widget.selected,
      depth: !widget.selected,
      opacity: !widget.selected,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: AppSpacing.xxl + AppSpacing.xs,
            height: _NavDestination._iconSlotHeight,
            child: AnimatedScale(
              scale: 1.0,
              duration: OraclySignatureMotion.pressRelease,
              curve: OraclySignatureMotion.releaseCurve,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: widget.selected ? 1.0 : 0.0,
                    duration: AppDuration.normal,
                    curve: Curves.easeOutCubic,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            blurRadius: AppShadowMetrics.iconBlur,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: AppSpacing.lg + AppSpacing.xs,
                        height: AppSpacing.lg + AppSpacing.xs,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: AppDuration.normal,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      widget.selected ? widget.data.selectedIcon : widget.data.icon,
                      key: ValueKey<bool>(widget.selected),
                      size: widget.selected
                          ? AppSpacing.lg + AppSpacing.xs
                          : AppSpacing.lg,
                      color: widget.selected ? AppColors.gold : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: _NavDestination._labelGap),
          AnimatedDefaultTextStyle(
            duration: AppDuration.normal,
            curve: Curves.easeOutCubic,
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: _NavDestination._labelFontSize,
              height: 1.0,
              color: widget.selected ? AppColors.goldLight : AppColors.textMuted,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: widget.selected ? 0.2 : 0,
            ),
            child: Text(
              widget.data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
