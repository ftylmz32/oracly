/// Feature → OR handoff quality — why the user arrived, without a dump.
library;

import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../ai/oracle_conversation/services/oracle_reading_context_text.dart';

/// Builds compact discovery context so OR does not ask the user to re-explain.
abstract final class OrDiscoveryHandoffQuality {
  OrDiscoveryHandoffQuality._();

  static const maxTotal = 400;
  static const maxBody = 280;

  static String compact(OracleReadingContext context) {
    final parts = <String>[_source(context)];
    switch (context.kind) {
      case OracleReadingKind.tarot:
        _tarot(parts, context);
      case OracleReadingKind.coffee:
        _obs(parts, context, symbols: true);
      case OracleReadingKind.astrology:
        _astro(parts, context);
      case OracleReadingKind.starMap:
      case OracleReadingKind.birthChart:
        _theme(parts, context);
      case OracleReadingKind.palm:
        _obs(parts, context, hand: true);
      case OracleReadingKind.dailyMessage:
        _theme(parts, context);
      default:
        _generic(parts, context);
    }
    return _cap(parts.where((p) => p.trim().isNotEmpty).join('\n'));
  }

  static void _tarot(List<String> parts, OracleReadingContext c) {
    final q = c.userQuestion?.trim();
    if (q != null && q.isNotEmpty) parts.add('Soru: $q');
    final cards = _cards(c);
    if (cards.isNotEmpty) {
      final spread = c.spreadLabel.trim();
      parts.add(spread.isEmpty ? cards : '$spread: $cards');
    }
    final summary = _summary(c);
    if (summary.isNotEmpty) parts.add(summary);
  }

  static void _obs(
    List<String> parts,
    OracleReadingContext c, {
    bool symbols = false,
    bool hand = false,
  }) {
    if (hand && c.spreadLabel.trim().isNotEmpty) parts.add(c.spreadLabel.trim());
    if (symbols) {
      final s = c.cardNames.where((n) => n.trim().isNotEmpty).join(', ');
      if (s.isNotEmpty) parts.add('İzler: $s');
    }
    parts.add(_body(c));
  }

  static void _astro(List<String> parts, OracleReadingContext c) {
    if (c.cardsSummary.trim().isNotEmpty) parts.add(c.cardsSummary.trim());
    parts.add(_body(c));
  }

  static void _theme(List<String> parts, OracleReadingContext c) {
    final theme = c.spreadLabel.trim().isNotEmpty
        ? c.spreadLabel.trim()
        : c.readingTitle.trim();
    if (theme.isNotEmpty) parts.add('Tema: $theme');
    parts.add(_body(c));
  }

  static void _generic(List<String> parts, OracleReadingContext c) {
    final q = c.userQuestion?.trim();
    if (q != null && q.isNotEmpty) parts.add('Soru: $q');
    parts.add(_body(c));
  }

  static String _body(OracleReadingContext c) {
    final full = (c.fullInterpretation ?? '').trim();
    if (full.isNotEmpty) {
      return OracleReadingContextText.shortSummary(full, maxLen: maxBody);
    }
    return _summary(c);
  }

  static String _summary(OracleReadingContext c) =>
      OracleReadingContextText.shortSummary(c.interpretationSummary, maxLen: 180);

  static String _cards(OracleReadingContext c) {
    final fromSummary = _stripIds(c.cardsSummary);
    if (fromSummary.isNotEmpty) return fromSummary;
    return c.cardNames.where((n) => n.trim().isNotEmpty).join(', ');
  }

  static String _stripIds(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';
    text = text.replaceAll(RegExp(r'\s*·\s*id:[A-Za-z0-9_-]+'), '');
    text = text.replaceAll(RegExp(r'\bid:[A-Za-z0-9_-]+\b'), '');
    return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _source(OracleReadingContext c) {
    final label = c.sourceLabel.trim();
    if (label.isNotEmpty) return label;
    return switch (c.kind) {
      OracleReadingKind.tarot => 'Tarot',
      OracleReadingKind.coffee => 'Kahve',
      OracleReadingKind.palm => 'El',
      OracleReadingKind.astrology => 'Astroloji',
      OracleReadingKind.starMap => 'Yıldızname',
      OracleReadingKind.dream => 'Rüya',
      OracleReadingKind.birthChart => 'Yıldızname',
      OracleReadingKind.dailyMessage => 'Günlük mesaj',
      OracleReadingKind.discoveryJournal => 'Keşif günlüğü',
      OracleReadingKind.soulMate => 'Ruh eşi',
    };
  }

  static String _cap(String text) {
    final t = text.trim();
    if (t.length <= maxTotal) return t;
    final cut = t.substring(0, maxTotal);
    final space = cut.lastIndexOf(' ');
    return '${space > maxTotal ~/ 2 ? cut.substring(0, space) : cut}…';
  }
}
