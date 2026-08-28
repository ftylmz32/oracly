/// Bottom nav destination labels — kept separate for line budget.
library;

import 'package:flutter/material.dart';

import '../../core/navigation/universe/oracly_tab_labels.dart';
import '../../shared/navigation/oracly_navigation.dart';

class OraclyBottomNavItemData {
  const OraclyBottomNavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

List<OraclyBottomNavItemData> oraclyBottomNavDestinations(String lang) => [
      OraclyBottomNavItemData(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: OraclyTab.home.labeled(lang),
      ),
      OraclyBottomNavItemData(
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome_rounded,
        label: OraclyTab.coffee.labeled(lang),
      ),
      OraclyBottomNavItemData(
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore_rounded,
        label: OraclyTab.astrology.labeled(lang),
      ),
      OraclyBottomNavItemData(
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        label: OraclyTab.starMap.labeled(lang),
      ),
      OraclyBottomNavItemData(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: OraclyTab.profile.labeled(lang),
      ),
    ];
