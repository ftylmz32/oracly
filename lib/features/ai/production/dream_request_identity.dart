/// Dream provider-request identity — every input that shapes the prompt.
///
/// Canonical form (v1): language normalized like the payload; narrative and
/// memory sanitized like the payload, then trimmed, lowercased and with
/// whitespace runs collapsed; symbols and emotions normalized the same way,
/// de-duplicated and sorted (they are sets in the prompt). Tags are already
/// folded into the narrative by `DreamContextEnricher`, so they count too.
/// Phase 4A prior-Dream history joins the canonical form only when present,
/// in prompt order, so a no-history request keeps its earlier identity and
/// any material history change is a different request.
/// Casing and whitespace-only edits are an exact retry; anything else is a
/// different request and never shares a coalesce, duplicate or replay key.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/l10n/l10n.dart';
import '../../gems/services/paid_ai_operation_binder.dart';
import '../services/prompt_sanitizer.dart';
import 'contexts/reading_ai_context.dart';

abstract final class DreamRequestIdentity {
  DreamRequestIdentity._();

  static const _prefix = 'dream:v1:';

  /// `dream:v1:<sha256 hex>` — used as guard key and duplicate fingerprint.
  static String fingerprint(DreamAiContext context) {
    final memory = context.memorySummary?.trim().isNotEmpty == true
        ? PromptSanitizer.sanitize(context.memorySummary!)
        : '';
    final canonical = jsonEncode({
      'language': AppLocale.normalize(context.language ?? OraclyL10n.code),
      'narrative': _text(PromptSanitizer.sanitize(context.narrative)),
      'symbols': _set(context.symbols),
      'emotions': _set(context.emotions),
      'memory': _text(memory),
      if (context.history.isNotEmpty)
        'history': [for (final item in context.history) _historyItem(item)],
    });
    return '$_prefix${sha256.convert(utf8.encode(canonical))}';
  }

  /// Provider replay key. A bound paid operation keeps its billing id as the
  /// prefix, but the semantic digest is always appended, so a reused binder
  /// can never replay a response produced for a different request body.
  static String idempotencyKey(String fingerprint) {
    final digest = fingerprint.startsWith(_prefix)
        ? fingerprint.substring(_prefix.length, _prefix.length + 32)
        : sha256.convert(utf8.encode(fingerprint)).toString().substring(0, 32);
    final binder = PaidAiOperationBinder.idempotencyKey;
    return binder == null ? 'dream-$digest' : '$binder:ds-$digest';
  }

  static String _historyItem(Map<String, Object> item) => [
        item['kind'],
        item['key'],
        _text('${item['label'] ?? ''}'),
        item['level'],
        item['priorCount'],
      ].join('|');

  static String _text(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static List<String> _set(List<String> values) =>
      ({for (final v in values) _text(v)}..remove('')).toList()..sort();
}
