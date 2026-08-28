/// Refuses private phrases instead of sharing a stripped leftover.
library;

import '../copy/discovery_share_copy.dart';

abstract final class DiscoveryShareSanitize {
  DiscoveryShareSanitize._();

  static const maxHighlight = 42;

  static String highlight(
    String raw, {
    List<String> denylist = const [],
    String? fallback,
  }) {
    final resolved = fallback ?? DiscoveryShareCopy.fallbackHighlight;
    var text = _firstPhrase(_symbolicLine(raw));
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty ||
        leaksPrivate(text) ||
        _containsDenied(text, denylist) ||
        _isSoulMateClaim(text)) {
      return resolved;
    }
    if (text.length > maxHighlight) {
      text = text.substring(0, maxHighlight).trim();
    }
    return text.isEmpty ? resolved : text;
  }

  static bool leaksPrivate(String text) {
    return _email.hasMatch(text) ||
        _isoDate.hasMatch(text) ||
        _trDate.hasMatch(text) ||
        _uuid.hasMatch(text) ||
        _token.hasMatch(text) ||
        _jwt.hasMatch(text) ||
        _prompt.hasMatch(text) ||
        _journal.hasMatch(text) ||
        _birth.hasMatch(text) ||
        _userId.hasMatch(text) ||
        _backend.hasMatch(text) ||
        _chat.hasMatch(text) ||
        _dream.hasMatch(text) ||
        _location.hasMatch(text);
  }

  static String _symbolicLine(String raw) {
    final match = RegExp(
      r'Sembolik mesaj\s*:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(raw);
    return (match?.group(1) ?? raw).trim();
  }

  static String _firstPhrase(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    final cut = trimmed.split(RegExp(r'\.(?:\s|$)|[!?\n]')).first.trim();
    return cut.isEmpty ? trimmed : cut;
  }

  static bool _containsDenied(String text, List<String> denylist) {
    final lower = text.toLowerCase();
    for (final item in denylist) {
      final needle = item.trim().toLowerCase();
      if (needle.length >= 2 && lower.contains(needle)) return true;
    }
    return false;
  }

  static bool _isSoulMateClaim(String text) {
    return _soulClaim.hasMatch(text);
  }

  static final _email = RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.]+\b');
  static final _isoDate = RegExp(r'\b\d{4}-\d{2}-\d{2}\b');
  static final _trDate = RegExp(r'\b\d{1,2}[./]\d{1,2}[./]\d{2,4}\b');
  static final _uuid = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
  );
  static final _token = RegExp(r'(sk-[A-Za-z0-9_-]+|Bearer\s+\S+)');
  static final _jwt = RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+');
  static final _prompt = RegExp(
    r'(system prompt|you are a|raw prompt)',
    caseSensitive: false,
  );
  static final _journal = RegExp(
    r'(günlüğüm|günlük not|full chat|keşif günlüğü|private journal|journal entry)',
    caseSensitive: false,
  );
  static final _birth = RegExp(
    r'(doğum tarihi|birth ?date|birthDate|birth_date)',
    caseSensitive: false,
  );
  static final _userId = RegExp(
    r'\b(user[_ ]?id|uid[=:][A-Za-z0-9_-]+|firebase uid)\b',
    caseSensitive: false,
  );
  static final _backend = RegExp(
    r'(api[_-]?key|supabase|backend token|authorization:)',
    caseSensitive: false,
  );
  static final _chat = RegExp(
    r'(full or chat|or sohbet|messagesJson|conversation record)',
    caseSensitive: false,
  );
  static final _dream = RegExp(
    r'(private dream|rüya kaydı|dream text|rüya günlüğü)',
    caseSensitive: false,
  );
  static final _location = RegExp(
    r'(\b\d{1,3}\.\d{3,},\s*-?\d{1,3}\.\d{3,}\b|'
    r'\blat(itude)?[=:\s]-?\d+\.\d+|\blng|lon(gitude)?[=:\s]-?\d+\.\d+|'
    r'\bexact location\b|\bkonum:\s*\S+|\bdoğum yeri:\s*\S+)',
    caseSensitive: false,
  );
  static final _soulClaim = RegExp(
    r'gerçek ruh eşi|gerçek ruh eşim|asıl ruh eşi|actual soulmate|'
    r'gerçek eşin|kesin karşına çıkacak',
    caseSensitive: false,
  );
}
