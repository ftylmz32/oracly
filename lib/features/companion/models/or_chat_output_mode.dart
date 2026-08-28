/// OR chat output — written, spoken replies, or voice conversation turns.
/// Preference only: never auto-starts the microphone.
library;

enum OrChatOutputMode {
  text,
  voice,
  conversation;

  bool get isVoice => this == voice || this == conversation;
  bool get isConversation => this == conversation;

  static const storageKey = 'settings_or_chat_output';

  String get wire => name;

  String get labelKey => 'or.output_mode.$name';

  static OrChatOutputMode fromStorage(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == conversation.name || value == 'talk') {
      return conversation;
    }
    if (value == voice.name || value == 'true' || value == '1') {
      return voice;
    }
    return text;
  }
}
