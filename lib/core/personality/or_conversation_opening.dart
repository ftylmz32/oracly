/// Natural OR open — conversation entry, never a help desk.
library;

import '../l10n/l10n.dart';
import 'or_phrase_rotator.dart';

abstract final class OrConversationOpening {
  OrConversationOpening._();

  /// Idle / first presence line when the user opens OR.
  static String line({
    String personality = 'mystical',
    DateTime? moment,
    String? name,
  }) {
    final day = moment ?? DateTime.now();
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final named = OrPhraseRotator.daily(
        pool: _namedPool(),
        day: day,
        salt: 'open_named_${_style(personality)}',
      );
      return named.replaceAll('{name}', trimmed);
    }
    return OrPhraseRotator.daily(
      pool: _pool(_style(personality)),
      day: day,
      salt: 'open_${_style(personality)}',
    );
  }

  static String _style(String raw) {
    final key = raw.trim().toLowerCase();
    return switch (key) {
      'gentle' || 'calm' => 'gentle',
      'direct' => 'direct',
      'poetic' || 'warm' => 'poetic',
      _ => 'mystical',
    };
  }

  /// Mostly statements; a few soft invites — never help-desk.
  static List<String> _pool(String style) {
    final base = [
      for (var i = 0; i < 6; i++) OraclyL10n.t('or.open.$i'),
    ];
    final tint = [
      for (var i = 0; i < 2; i++) OraclyL10n.t('or.open.$style.$i'),
    ];
    return [...base, ...tint];
  }

  static List<String> _namedPool() => [
        for (var i = 0; i < 4; i++) OraclyL10n.t('or.open.named.$i'),
      ];
}
