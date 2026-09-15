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
    return _hasWord(lower, symbol.label.toLowerCase()) ||
        _hasWord(lower, symbol.token.toLowerCase());
  }

  static String? _firstWhere(List<String> values, String lower) {
    for (final value in values) {
      if (value.trim().isEmpty) continue;
      if (_hasWord(lower, value.toLowerCase()) ||
          _hasWord(lower, value.toLowerCase().split(' ').first)) {
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
      if (_hasWord(lower, label.toLowerCase())) return label;
    }
    return people
        .map((p) => p.label.trim())
        .where((l) => l.isNotEmpty)
        .firstOrNull;
  }

  /// True if [token] occurs in [text] at a real word start -- e.g. "tren"
  /// matches inside "trenin"/"treni" (Turkish inflects by suffixing only),
  /// but "at" does not match inside "saat" and "ay" does not match inside
  /// "ray"/"raylar", because a genuine match can never have a letter
  /// immediately before it.
  static bool _hasWord(String text, String token) {
    if (token.isEmpty) return false;
    var index = text.indexOf(token);
    while (index != -1) {
      final before = index == 0 ? null : text[index - 1];
      if (before == null || !_isTurkishLetter(before)) return true;
      index = text.indexOf(token, index + 1);
    }
    return false;
  }

  static bool _isTurkishLetter(String char) =>
      RegExp(r'[a-zçğıöşü]', unicode: true).hasMatch(char);

  static String _scene(String told) {
    var text = told.trim();
    text = text.replaceFirst(RegExp(r'^[Rr]üyamda\s+'), '');
    if (text.isEmpty) return '';
    final period = text.indexOf(RegExp(r'[.!?]'));
    if (period > 8 && period < 110) {
      return _trimEdge(text.substring(0, period));
    }
    // No early sentence end (a long, comma/conjunction-joined run-on, which
    // real dream narratives often are). Only take a fragment if it stops at
    // a pause the narrative itself contains -- never hard-cut a run-on at an
    // arbitrary word boundary, which can splice half a clause into a
    // template and read as broken grammar.
    final pause = text.indexOf(
      RegExp(r',| ve | ile | ama | fakat | ancak | derken '),
    );
    if (pause > 8 && pause < 88) return _trimEdge(text.substring(0, pause));
    return '';
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
