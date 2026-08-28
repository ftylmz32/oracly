/// One rolling chat turn — user or assistant, never secrets.
library;

class ConversationTurn {
  const ConversationTurn({required this.role, required this.text});

  factory ConversationTurn.user(String text) =>
      ConversationTurn(role: userRole, text: text.trim());

  factory ConversationTurn.assistant(String text) =>
      ConversationTurn(role: assistantRole, text: text.trim());

  static const userRole = 'user';
  static const assistantRole = 'assistant';
  static const maxWindow = 8;
  static const maxText = 800;

  final String role;
  final String text;

  bool get isUser => role == userRole;

  Map<String, String> toPayload() => {
        'role': isUser ? userRole : assistantRole,
        'text': text.length <= maxText ? text : text.substring(0, maxText),
      };

  static List<ConversationTurn> takeRecent(List<ConversationTurn> all) {
    final clean = [
      for (final turn in all)
        if (turn.text.trim().isNotEmpty)
          ConversationTurn(
            role: turn.isUser ? userRole : assistantRole,
            text: turn.text.trim(),
          ),
    ];
    if (clean.length <= maxWindow) return clean;
    return clean.sublist(clean.length - maxWindow);
  }

  static ConversationTurn? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final role = raw['role']?.toString();
    final text = (raw['text'] ?? raw['content'])?.toString() ?? '';
    if (text.trim().isEmpty) return null;
    if (role == assistantRole) return ConversationTurn.assistant(text);
    if (role == userRole) return ConversationTurn.user(text);
    return null;
  }

  static List<ConversationTurn> parseList(Object? raw) {
    if (raw is! List) return const [];
    return takeRecent([
      for (final item in raw) ?tryParse(item),
    ]);
  }
}
