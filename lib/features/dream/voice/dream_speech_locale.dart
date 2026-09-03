/// Resolves OS speech locale for TR / EN / RU — honest when unsupported.
library;

import '../../../core/l10n/app_locale.dart';

typedef SpeechLocaleId = String;

String? resolveDreamSpeechLocale(
  Iterable<SpeechLocaleId> available,
  String appLanguageCode,
) {
  final want = AppLocale.normalize(appLanguageCode);
  final ids = available.map(_normalizeId).toList();
  if (ids.isEmpty) return null;

  final exact = switch (want) {
    AppLocale.en => const ['en_us', 'en_gb', 'en'],
    AppLocale.ru => const ['ru_ru', 'ru'],
    _ => const ['tr_tr', 'tr'],
  };
  for (final candidate in exact) {
    for (final id in ids) {
      if (id == candidate || _startsWithPrefix(id, candidate)) {
        return _originalId(available, id);
      }
    }
  }

  final prefix = want == AppLocale.en
      ? 'en'
      : want == AppLocale.ru
          ? 'ru'
          : 'tr';
  for (final id in ids) {
    if (id == prefix || _startsWithPrefix(id, prefix)) {
      return _originalId(available, id);
    }
  }
  return null;
}

bool _startsWithPrefix(String id, String prefix) {
  if (!id.startsWith(prefix)) return false;
  if (id.length == prefix.length) return true;
  return id[prefix.length] == '_';
}

String _normalizeId(SpeechLocaleId id) =>
    id.toLowerCase().replaceAll('-', '_');

String _originalId(Iterable<SpeechLocaleId> available, String normalized) {
  for (final id in available) {
    if (_normalizeId(id) == normalized) return id;
  }
  return normalized;
}