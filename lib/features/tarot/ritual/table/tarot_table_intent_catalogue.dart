/// Intention chip catalogue for the live Tarot table.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

class TableIntentOption {
  const TableIntentOption({
    required this.id,
    required this.icon,
  });

  final String id;
  final IconData icon;

  String get title => TableIntentCatalogue.title(id);
}

abstract final class TableIntentCatalogue {
  TableIntentCatalogue._();

  static const options = [
    TableIntentOption(id: 'love', icon: Icons.favorite_rounded),
    TableIntentOption(id: 'career', icon: Icons.work_outline_rounded),
    TableIntentOption(id: 'future', icon: Icons.auto_awesome_rounded),
    TableIntentOption(id: 'inner', icon: Icons.nightlight_round),
    TableIntentOption(id: 'custom', icon: Icons.edit_outlined),
  ];

  static String title(String id) => switch (id) {
        'love' => OraclyL10n.t('tarot.love'),
        'career' => OraclyL10n.t('tarot.career'),
        'future' => OraclyL10n.t('tarot.intent.chip.future'),
        'inner' => OraclyL10n.t('tarot.intent.chip.inner'),
        'custom' => OraclyL10n.t('tarot.intent.chip.custom'),
        _ => id,
      };
}
