/// OR-1150 — Dream symbol content models.
library;

import '../../shared/services/content_search_service.dart';

enum DreamSymbolCategory {
  animals,
  objects,
  people,
  colors,
  numbers,
  places,
  religious,
  nature,
  weather,
  emotions,
}

class DreamSymbolContent implements SearchableContent {
  const DreamSymbolContent({
    required this.id,
    required this.token,
    required this.tokenTr,
    required this.category,
    required this.meaning,
    required this.psychologicalNote,
    required this.relatedSymbols,
    required this.tagList,
  });

  final String id;
  final String token;
  final String tokenTr;
  final DreamSymbolCategory category;
  final String meaning;
  final String psychologicalNote;
  final List<String> relatedSymbols;
  final List<String> tagList;

  @override
  String get contentId => id;

  @override
  String get displayName => tokenTr;

  @override
  String get searchText =>
      '$token $tokenTr $meaning ${tagList.join(' ')} ${category.name}';

  @override
  List<String> get categories => [category.name];

  @override
  List<String> get tags => tagList;

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'tokenTr': tokenTr,
        'category': category.name,
        'meaning': meaning,
        'psychologicalNote': psychologicalNote,
        'relatedSymbols': relatedSymbols,
        'tags': tagList,
      };

  factory DreamSymbolContent.fromJson(Map<String, dynamic> json) {
    return DreamSymbolContent(
      id: json['id'] as String,
      token: json['token'] as String,
      tokenTr: json['tokenTr'] as String,
      category: DreamSymbolCategory.values.byName(json['category'] as String),
      meaning: json['meaning'] as String,
      psychologicalNote: json['psychologicalNote'] as String,
      relatedSymbols: (json['relatedSymbols'] as List<dynamic>).cast<String>(),
      tagList: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }
}
