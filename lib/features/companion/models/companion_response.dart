/// Local OR reply payload.
library;

class CompanionResponse {
  const CompanionResponse({
    required this.body,
    this.suggestions = const [],
    this.speechGrant,
  });

  final String body;
  final List<String> suggestions;
  final String? speechGrant;
}
