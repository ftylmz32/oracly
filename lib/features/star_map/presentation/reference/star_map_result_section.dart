/// One titled Yıldızname result block.
library;

import '../../result/yildizname_result_types.dart';

class StarMapResultSection {
  const StarMapResultSection({
    required this.title,
    required this.body,
    this.role = YildiznameSectionRole.chapter,
  });

  /// Display-ready chrome. Never a wire name, enum name, or identifier.
  final String title;

  /// Stored prose — immutable, never localized or rewritten.
  final String body;

  /// Semantic role, so later phases can style summary / chapter / reflection /
  /// closing apart without re-parsing titles.
  final YildiznameSectionRole role;

  @override
  bool operator ==(Object other) =>
      other is StarMapResultSection &&
      other.title == title &&
      other.body == body &&
      other.role == role;

  @override
  int get hashCode => Object.hash(title, body, role);
}
