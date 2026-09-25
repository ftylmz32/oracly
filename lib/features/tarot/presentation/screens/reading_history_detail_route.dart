/// History detail route helper.
library;

import 'package:flutter/material.dart';

import '../../../../core/navigation/oracly_page_transitions.dart';
import '../widgets/reading_history/reading_history_data.dart';
import 'reading_history_detail_screen.dart';

Route<T> historyDetailRoute<T>({required ReadingHistoryEntry entry}) {
  return OraclyPageTransitions.fade<T>(
    page: ReadingHistoryDetailScreen(entry: entry),
    settings: RouteSettings(name: '/tarot/history/${entry.id}'),
    duration: const Duration(milliseconds: 480),
    reverseDuration: const Duration(milliseconds: 360),
  );
}
