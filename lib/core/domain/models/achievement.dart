/// OR-1100 — Achievement domain model.
library;

import 'package:flutter/material.dart';

class AchievementModel {
  const AchievementModel({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final DateTime? unlockedAt;
}
