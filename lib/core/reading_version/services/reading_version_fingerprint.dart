/// Detects meaningful differences between interpretation snapshots.
library;

import '../models/reading_version_kind.dart';

abstract final class ReadingVersionFingerprint {
  ReadingVersionFingerprint._();

  static String of(Map<String, dynamic> data, ReadingVersionKind kind) {
    final text = switch (kind) {
      ReadingVersionKind.tarot => '${data['summary'] ?? ''}',
      ReadingVersionKind.coffee => _coffeeText(data),
      ReadingVersionKind.palm => _palmText(data),
      ReadingVersionKind.dream => '${data['analysis'] ?? ''}',
    };
    return _normalize(text);
  }

  static bool isMeaningful(String previous, String next) =>
      _normalize(previous) != _normalize(next);

  static String _coffeeText(Map<String, dynamic> data) {
    final symbols = data['symbols'];
    final symbolText = symbols is List
        ? [
            for (final item in symbols)
              if (item is Map)
                '${item['name'] ?? ''}:${item['meaning'] ?? ''}:'
                    '${item['interpretation'] ?? ''}',
          ].join('|')
        : '';
    return [
      data['overall'],
      data['love'],
      data['career'],
      data['money'],
      data['nearFuture'],
      data['takeaway'],
      data['visualObservation'],
      symbolText,
    ].join('\n');
  }

  static String _palmText(Map<String, dynamic> data) {
    final symbols = data['symbols'];
    final themes = data['themes'];
    final symbolText = symbols is List
        ? [
            for (final item in symbols)
              if (item is String) item,
          ].join('|')
        : '';
    final themeText = themes is List
        ? [
            for (final item in themes)
              if (item is String) item,
          ].join('|')
        : '';
    return [
      data['overall'],
      data['lifeLine'],
      data['headLine'],
      data['heartLine'],
      data['fateLine'],
      data['takeaway'],
      symbolText,
      themeText,
    ].join('\n');
  }

  static String _normalize(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
