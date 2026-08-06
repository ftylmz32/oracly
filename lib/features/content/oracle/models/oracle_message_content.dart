/// OR-1150 — Oracle wisdom message content.
library;

import '../../shared/services/content_search_service.dart';

enum OracleMessageTheme {
  guidance,
  warning,
  blessing,
  reflection,
  action,
}

class OracleMessageContent implements SearchableContent {
  const OracleMessageContent({
    required this.id,
    required this.title,
    required this.body,
    required this.theme,
    required this.source,
  });

  final String id;
  final String title;
  final String body;
  final OracleMessageTheme theme;
  final String source;

  @override
  String get contentId => id;

  @override
  String get displayName => title;

  @override
  String get searchText => '$title $body $source ${theme.name}';

  @override
  List<String> get categories => [theme.name, source];

  @override
  List<String> get tags => [source, theme.name];
}
