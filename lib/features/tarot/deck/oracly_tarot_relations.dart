/// How this card may converse with others — ids + a reflective note.
library;

import '../../../core/l10n/l10n_triple.dart';

class OraclyTarotRelations {
  const OraclyTarotRelations({
    required this.relatedIds,
    required this.note,
  });

  final List<String> relatedIds;
  final L10nTriple note;

  bool get isComplete =>
      relatedIds.isNotEmpty &&
      relatedIds.every((id) => id.trim().isNotEmpty) &&
      note.tr.trim().isNotEmpty &&
      note.en.trim().isNotEmpty &&
      note.ru.trim().isNotEmpty;
}
