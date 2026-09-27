/// Dream Phase 4A — the one definition of "the same" across saved Dreams.
///
/// Keys come only from structured fields, compared by exact equality:
/// - catalogue symbols by catalogue token (one entry's TR and EN words are
///   one key); lexicon-only symbols by their normalized token;
/// - locations and relationships by their normalized stored label;
/// - emotions and entry chips by stable ids, whatever the UI language was.
/// Free-form tags, guided answers and provider prose never become keys.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/text/turkish_lexical_matcher.dart';
import '../../content/dream/data/dream_symbol_catalogue.dart';
import '../models/dream.dart';
import '../models/dream_entry_context.dart';
import '../models/dream_relationship.dart';
import '../models/dream_symbol.dart';
import 'dream_history_evidence.dart';

typedef DreamHistoryEntry = ({DreamHistoryEvidenceKind kind, String label});

abstract final class DreamHistoryIdentity {
  DreamHistoryIdentity._();

  /// Canonical key → kind and label in [language], for one dream.
  static Map<String, DreamHistoryEntry> entries(Dream dream, String language) {
    final out = <String, DreamHistoryEntry>{};
    void add(DreamHistoryEvidenceKind kind, String key, String label) {
      if (key.endsWith(':') || label.trim().isEmpty) return;
      out.putIfAbsent(key, () => (kind: kind, label: label.trim()));
    }

    final understanding = dream.understanding;
    for (final symbol in understanding?.symbols ?? const <DreamSymbol>[]) {
      final item = DreamSymbolCatalogue.byToken(symbol.token);
      if (item != null) {
        final label = language == AppLocale.en ? item.token : item.tokenTr;
        add(_symbol, 'symbol:${_norm(item.token)}', label);
      } else {
        add(_symbol, 'symbol:${_norm(symbol.token)}', symbol.label);
      }
    }
    for (final location in understanding?.locations ?? const <String>[]) {
      add(DreamHistoryEvidenceKind.location, 'location:${_norm(location)}',
          location);
    }
    for (final person
        in understanding?.relationships ?? const <DreamRelationship>[]) {
      add(DreamHistoryEvidenceKind.relationship,
          'relationship:${_norm(person.label)}', person.label);
    }
    for (final emotion in dream.selectedEmotions) {
      final id = emotion.id.name;
      add(DreamHistoryEvidenceKind.emotion, 'emotion:$id',
          _t('dream.read.feeling_word.$id', language));
    }
    for (final chip in dream.entry?.chips ?? const <DreamEntryChipId>[]) {
      add(DreamHistoryEvidenceKind.entry, 'entry:${chip.name}',
          _t('dream.chip_${chip.name}', language));
    }
    return out;
  }

  static const _symbol = DreamHistoryEvidenceKind.symbol;

  static String _norm(String value) => TurkishLexicalMatcher.normalize(value)
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static String _t(String key, String language) =>
      OraclyL10n.t(key, languageCode: language);
}
