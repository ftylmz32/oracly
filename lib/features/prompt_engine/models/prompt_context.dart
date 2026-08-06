/// OR-1160 — Runtime context passed into every prompt build.
library;

class PromptContext {
  const PromptContext({
    this.locale = 'tr',
    this.personality = 'mystical',
    this.sessionId,
    this.userName,
    this.facts = const {},
    this.variables = const {},
    this.conversationHistory = const [],
  });

  final String locale;
  final String personality;
  final String? sessionId;
  final String? userName;
  final Map<String, dynamic> facts;
  final Map<String, dynamic> variables;
  final List<Map<String, String>> conversationHistory;

  Map<String, dynamic> toVariableMap() => {
        'locale': locale,
        'personality': personality,
        if (sessionId != null) 'sessionId': sessionId,
        if (userName != null) 'userName': userName,
        ...facts,
        ...variables,
      };

  PromptContext mergeVariables(Map<String, dynamic> extra) {
    return PromptContext(
      locale: locale,
      personality: personality,
      sessionId: sessionId,
      userName: userName,
      facts: facts,
      variables: {...variables, ...extra},
      conversationHistory: conversationHistory,
    );
  }

  PromptContext copyWith({
    String? locale,
    String? personality,
    Map<String, dynamic>? facts,
    Map<String, dynamic>? variables,
  }) {
    return PromptContext(
      locale: locale ?? this.locale,
      personality: personality ?? this.personality,
      sessionId: sessionId,
      userName: userName,
      facts: facts ?? this.facts,
      variables: variables ?? this.variables,
      conversationHistory: conversationHistory,
    );
  }
}
