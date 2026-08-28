/// Observed dream facts — told text only, never a life story.
library;

import '../models/dream.dart';
import '../models/dream_relationship.dart';
import '../models/dream_symbol.dart';

class DreamAnalysisFacts {
  const DreamAnalysisFacts({
    required this.told,
    required this.scene,
    this.emotion,
    this.image,
    this.companion,
    this.place,
    this.person,
    this.tag,
    this.detail,
  });

  final String told;
  final String scene;
  final String? emotion;
  final String? image;
  final String? companion;
  final String? place;
  final String? person;
  final String? tag;
  final String? detail;

  bool get isEmpty => told.isEmpty;

  static DreamAnalysisFacts from({
    required String narrative,
    required DreamUnderstanding understanding,
    List<String> tags = const [],
  }) {
    final told = narrative.trim().replaceAll(RegExp(r'\s+'), ' ');
    final lower = told.toLowerCase();
    final images = [
      for (final symbol in understanding.symbols)
        if (_appears(lower, symbol)) symbol.label,
    ];
    final place = _firstWhere(understanding.locations, lower);
    final person = _firstPerson(understanding.relationships, lower);
    final emotion = understanding.emotions.isEmpty
        ? null
        : understanding.emotions.first;
    final tag = tags.where((t) => t.trim().isNotEmpty).firstOrNull;
    final image = images.isEmpty ? null : images.first;
    final companion = images.length > 1 ? images[1] : null;
    final detail = _detail(
      image: image,
      place: place,
      person: person,
      scene: _scene(told),
    );
    return DreamAnalysisFacts(
      told: told,
      scene: _scene(told),
      emotion: emotion,
      image: image,
      companion: companion,
      place: place,
      person: person,
      tag: tag,
      detail: detail,
    );
  }

  static bool _appears(String lower, DreamSymbol symbol) {
    return lower.contains(symbol.label.toLowerCase()) ||
        lower.contains(symbol.token.toLowerCase());
  }

  static String? _firstWhere(List<String> values, String lower) {
    for (final value in values) {
      if (value.trim().isEmpty) continue;
      if (lower.contains(value.toLowerCase()) ||
          lower.contains(value.toLowerCase().split(' ').first)) {
        return value;
      }
    }
    return values.where((v) => v.trim().isNotEmpty).firstOrNull;
  }

  static String? _firstPerson(
    List<DreamRelationship> people,
    String lower,
  ) {
    for (final person in people) {
      final label = person.label.trim();
      if (label.isEmpty) continue;
      if (lower.contains(label.toLowerCase())) return label;
    }
    return people
        .map((p) => p.label.trim())
        .where((l) => l.isNotEmpty)
        .firstOrNull;
  }

  static String _scene(String told) {
    var text = told.trim();
    text = text.replaceFirst(RegExp(r'^[Rr]üyamda\s+'), '');
    if (text.isEmpty) return '';
    final i = text.indexOf(RegExp(r'[.!?]'));
    final clause = i > 8 && i < 110 ? text.substring(0, i) : text;
    if (clause.length <= 88) return _trimEdge(clause);
    final cut = clause.substring(0, 88);
    final sp = cut.lastIndexOf(' ');
    return _trimEdge(sp > 24 ? cut.substring(0, sp) : cut);
  }

  static String? _detail({
    String? image,
    String? place,
    String? person,
    required String scene,
  }) {
    if (image != null &&
        place != null &&
        image.toLowerCase() != place.toLowerCase()) {
      return '$image, $place içinde';
    }
    if (image != null && person != null) return '$image ve $person';
    if (person != null && place != null) return '$person, $place içinde';
    if (image != null) return image;
    if (person != null) return person;
    if (place != null) return place;
    if (scene.isNotEmpty) return scene;
    return null;
  }

  static String _trimEdge(String text) {
    var out = text.trim();
    while (out.endsWith(',') || out.endsWith('—') || out.endsWith('-')) {
      out = out.substring(0, out.length - 1).trim();
    }
    return out;
  }
}
