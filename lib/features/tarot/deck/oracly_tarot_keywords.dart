/// Localized keyword lists — same length in TR / EN / RU.
library;

import '../../../core/l10n/app_locale.dart';

class OraclyTarotKeywords {
  const OraclyTarotKeywords({
    required this.tr,
    required this.en,
    required this.ru,
  });

  final List<String> tr;
  final List<String> en;
  final List<String> ru;

  List<String> of(String languageCode) {
    return switch (AppLocale.normalize(languageCode)) {
      AppLocale.en => en,
      AppLocale.ru => ru,
      _ => tr,
    };
  }

  bool get isComplete =>
      tr.isNotEmpty &&
      en.length == tr.length &&
      ru.length == tr.length &&
      tr.every((w) => w.trim().isNotEmpty) &&
      en.every((w) => w.trim().isNotEmpty) &&
      ru.every((w) => w.trim().isNotEmpty);
}
