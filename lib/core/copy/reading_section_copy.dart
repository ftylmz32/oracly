/// TASK-001 — Reading screen section labels aligned to emotional flow.
library;

import '../../features/tarot/presentation/widgets/ai_reading/reading_section_theme.dart';

/// Section titles that guide the eye: meaning → understanding → pause → peace.
abstract final class ReadingSectionCopy {
  ReadingSectionCopy._();

  /// Opening beat — card title area (header widget).
  static const headingHint = 'Kartın';

  /// First interpretation block — curiosity.
  static const meaning = 'Anlam';

  /// Life-area readings — understanding deepens.
  static const love = 'Aşk';
  static const career = 'Kariyer';
  static const money = 'Para';

  /// Invites inward attention — question beat.
  static const spiritual = 'Düşünmeye Alan';

  static const hidden = 'Derin Mesaj';

  /// Gentle forward motion — suggestion beat.
  static const suggestion = 'Bugün İçin';

  static const lucky = 'Şanslı Enerji';

  /// Affirmation beat before closing.
  static const questionPrompt = 'Kendine Sor';

  /// Final reflection block.
  static const closing = 'Son Yansıma';

  /// Whisper labels between major acts — visual connectors only.
  static const bridgeToMeaning = 'Yorum açılıyor';
  static const bridgeToReflection = 'Anlam derinleşiyor';
  static const bridgeToClosing = 'Bir an dur';

  static String titleFor(ReadingSectionKind kind) {
    return switch (kind) {
      ReadingSectionKind.general => meaning,
      ReadingSectionKind.love => love,
      ReadingSectionKind.career => career,
      ReadingSectionKind.money => money,
      ReadingSectionKind.spiritual => spiritual,
      ReadingSectionKind.hidden => hidden,
      ReadingSectionKind.warning => suggestion,
      ReadingSectionKind.lucky => lucky,
    };
  }
}
