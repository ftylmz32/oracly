/// Typed, display-ready natal fact snapshot.
///
/// Built ONLY from the stored structured request of an accepted reading, and
/// only up to the already-resolved scope. Widgets receive finished, localized
/// strings — never provider maps, wire values, or fact references.
library;

import 'package:flutter/foundation.dart';

/// Which body / angle a fact describes (typed, not a wire value).
enum YildiznameFactSubject {
  sun,
  moon,
  ascendant,
  midheaven,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
}

/// Visual priority of a fact.
enum YildiznameFactGroup { primary, secondary, outer }

@immutable
final class YildiznameDisplayFact {
  const YildiznameDisplayFact({
    required this.subject,
    required this.group,
    required this.label,
    required this.value,
    this.detail,
  });

  final YildiznameFactSubject subject;
  final YildiznameFactGroup group;

  /// Localized body / angle name.
  final String label;

  /// Localized sign name.
  final String value;

  /// Optional whole-degree / house / retrograde detail (FULL, exact facts only).
  final String? detail;

  /// One calm sentence for assistive technology, in visual order.
  String get semanticsLabel =>
      detail == null ? '$label, $value' : '$label, $value, $detail';

  @override
  bool operator ==(Object other) =>
      other is YildiznameDisplayFact &&
      other.subject == subject &&
      other.group == group &&
      other.label == label &&
      other.value == value &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(subject, group, label, value, detail);
}

/// A structured aspect between two displayed bodies (FULL only).
@immutable
final class YildiznameDisplayAspect {
  const YildiznameDisplayAspect({
    required this.first,
    required this.second,
    required this.type,
  });

  /// Localized body names, in a fixed body order.
  final String first;
  final String second;

  /// Localized aspect name.
  final String type;

  String get semanticsLabel => '$first, $second, $type';

  @override
  bool operator ==(Object other) =>
      other is YildiznameDisplayAspect &&
      other.first == first &&
      other.second == second &&
      other.type == type;

  @override
  int get hashCode => Object.hash(first, second, type);
}

/// A localized label / value line (dominant element, dominant quality).
@immutable
final class YildiznameDisplayBalance {
  const YildiznameDisplayBalance({required this.label, required this.value});

  final String label;
  final String value;

  String get semanticsLabel => '$label, $value';

  @override
  bool operator ==(Object other) =>
      other is YildiznameDisplayBalance &&
      other.label == label &&
      other.value == value;

  @override
  int get hashCode => Object.hash(label, value);
}

@immutable
final class YildiznameFactSnapshot {
  const YildiznameFactSnapshot({
    required this.title,
    required this.moreLabel,
    this.primary = const [],
    this.secondary = const [],
    this.outer = const [],
    this.outerLabel = '',
    this.aspects = const [],
    this.aspectsLabel = '',
    this.balances = const [],
  });

  /// No facts — legacy results, unproven / malformed evidence, old artifacts.
  static const empty = YildiznameFactSnapshot(title: '', moreLabel: '');

  /// Localized plate title.
  final String title;

  /// Localized label of the deeper-layer toggle.
  final String moreLabel;

  /// Sun · Moon · Ascendant · Midheaven — only those really stored.
  final List<YildiznameDisplayFact> primary;

  /// Mercury · Venus · Mars.
  final List<YildiznameDisplayFact> secondary;

  /// Jupiter · Saturn · Uranus · Neptune · Pluto.
  final List<YildiznameDisplayFact> outer;
  final String outerLabel;

  /// Tightest aspects between displayed bodies (FULL only), capped.
  final List<YildiznameDisplayAspect> aspects;
  final String aspectsLabel;

  /// Dominant element / quality (FULL only).
  final List<YildiznameDisplayBalance> balances;

  bool get isEmpty =>
      primary.isEmpty &&
      secondary.isEmpty &&
      outer.isEmpty &&
      aspects.isEmpty &&
      balances.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// True when the collapsed-by-default deeper layer has content.
  bool get hasDeeper =>
      outer.isNotEmpty || aspects.isNotEmpty || balances.isNotEmpty;

  /// Every placement / angle fact in stable priority order.
  List<YildiznameDisplayFact> get facts => [...primary, ...secondary, ...outer];

  @override
  bool operator ==(Object other) =>
      other is YildiznameFactSnapshot &&
      other.title == title &&
      other.moreLabel == moreLabel &&
      other.outerLabel == outerLabel &&
      other.aspectsLabel == aspectsLabel &&
      listEquals(other.primary, primary) &&
      listEquals(other.secondary, secondary) &&
      listEquals(other.outer, outer) &&
      listEquals(other.aspects, aspects) &&
      listEquals(other.balances, balances);

  @override
  int get hashCode => Object.hash(
    title,
    moreLabel,
    outerLabel,
    aspectsLabel,
    Object.hashAll(primary),
    Object.hashAll(secondary),
    Object.hashAll(outer),
    Object.hashAll(aspects),
    Object.hashAll(balances),
  );
}
