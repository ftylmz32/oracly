/// Local OR reply payload.
library;

class CompanionResponse {
  const CompanionResponse({required this.body, this.suggestions = const []});

  final String body;
  final List<String> suggestions;
}
