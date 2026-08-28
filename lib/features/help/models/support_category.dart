/// Predefined support categories — metadata only, never free-text readings.
library;

enum SupportCategory {
  orSilent,
  readingFailed,
  tarot,
  imageFailed,
  gems,
  language,
}

extension SupportCategoryMeta on SupportCategory {
  /// Safe wire for mail / analytics — no user content.
  String get errorCategory => switch (this) {
        SupportCategory.orSilent => 'or_silent',
        SupportCategory.readingFailed => 'reading_failed',
        SupportCategory.tarot => 'tarot',
        SupportCategory.imageFailed => 'image_failed',
        SupportCategory.gems => 'gems',
        SupportCategory.language => 'language',
      };

  String get feature => switch (this) {
        SupportCategory.orSilent => 'companion',
        SupportCategory.readingFailed => 'reading',
        SupportCategory.tarot => 'tarot',
        SupportCategory.imageFailed => 'soulmate',
        SupportCategory.gems => 'gems',
        SupportCategory.language => 'language',
      };

  String get labelKey => 'help.category.$errorCategory';
}
