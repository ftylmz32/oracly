/// Upgraded-install compatibility for Tarot history / active prefs.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/data/datasources/local_storage.dart';
import 'tarot_local_datasource.dart';

/// Reads Tarot history rows without throwing on legacy / wrong-type prefs.
///
/// Migrates recoverable shapes forward once. Discards only unrecoverable
/// Tarot keys — never wipes unrelated SharedPreferences.
abstract final class TarotHistoryCompat {
  TarotHistoryCompat._();

  static Future<List<String>> readHistoryRows(LocalStorage storage) async {
    final raw = storage.peek(TarotLocalDataSource.historyKey);
    if (raw == null) return const [];

    if (raw is List) {
      final rows = <String>[];
      for (final item in raw) {
        if (item is String) {
          rows.add(item);
        } else if (item is Map) {
          rows.add(jsonEncode(item));
        }
      }
      if (raw is! List<String>) {
        await storage.setStringList(TarotLocalDataSource.historyKey, rows);
        debugPrint(
          '[TarotHistoryCompat] normalized history List→StringList '
          '(${rows.length})',
        );
      }
      return rows;
    }

    if (raw is String) {
      final rows = rowsFromLegacyString(raw);
      await storage.setStringList(TarotLocalDataSource.historyKey, rows);
      debugPrint(
        '[TarotHistoryCompat] migrated history String→StringList '
        '(${rows.length})',
      );
      return rows;
    }

    debugPrint(
      '[TarotHistoryCompat] discarding history type ${raw.runtimeType}',
    );
    await storage.remove(TarotLocalDataSource.historyKey);
    return const [];
  }

  static Future<String?> readActiveRaw(LocalStorage storage) async {
    final raw = storage.peek(TarotLocalDataSource.activeKey);
    if (raw == null) return null;
    if (raw is String) return raw;
    debugPrint(
      '[TarotHistoryCompat] discarding active type ${raw.runtimeType}',
    );
    await storage.remove(TarotLocalDataSource.activeKey);
    return null;
  }

  /// Recover rows from a legacy JSON string blob.
  static List<String> rowsFromLegacyString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        final rows = <String>[];
        for (final item in decoded) {
          if (item is String) {
            rows.add(item);
          } else if (item is Map) {
            rows.add(jsonEncode(item));
          }
        }
        return rows;
      }
      if (decoded is Map) return [jsonEncode(decoded)];
    } catch (e) {
      debugPrint('[TarotHistoryCompat] legacy history decode failed: $e');
    }
    return const [];
  }
}
