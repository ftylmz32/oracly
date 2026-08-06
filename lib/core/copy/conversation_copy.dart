/// RC-002 — AI conversation copy: calm companion, not chatbot.
library;

abstract final class ConversationCopy {
  ConversationCopy._();

  /// Tab chat companion subtitle — not "online" status.
  static const companionSubtitle = 'Sakin bir yansıma alanı';

  static const inputHint = 'Düşünceni paylaş…';

  static const oracleInputHint = 'Kartların hakkında düşünmek istediğin ne?';

  static const thinkingLabel = 'OR dinliyor…';

  static const oracleThinkingLabel = 'OR düşünüyor…';

  static const oracleEmptyTitle = 'Bu açılım hâlâ seninle.';

  static const oracleEmptyBody =
      'Kartların mesajını birlikte derinleştirebiliriz. '
      'Aşağıdaki bir soruyla başlayabilir veya kendi cümleini yazabilirsin.';

  /// Gentle permission to leave — no pressure to continue.
  static const closingWhisper =
      'Bu sohbet seninle kalabilir. Devam etmek zorunda değilsin — '
      'huzurla ayrılabilirsin.';

  /// First message for tab chat — welcoming, not generic chatbot.
  static String welcome({String? name}) {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return 'Merhaba, $trimmed.\n'
          'Burada acele yok — birlikte düşünmek için buradayım. '
          'Bugün aklında ne var?';
    }
    return 'Merhaba.\n'
        'Burada acele yok — birlikte düşünmek için buradayım. '
        'Bugün aklında ne var?';
  }

  /// Reflective suggestion chips — invite thought, not commands.
  static const oracleSuggestions = [
    'Bu kart bana ne hissettiriyor?',
    'Açılımda en çok ne dikkatimi çekti?',
    'Bu mesajı günlük hayatıma nasıl taşıyabilirim?',
    'Şu an netleşmek istediğim ne?',
    'Bir adım geri çekilsem ne görürdüm?',
  ];
}
