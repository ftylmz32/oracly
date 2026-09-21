/// Tri-state classification for ORACLY-managed files under app documents.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum ManagedPathKind {
  /// Proven ORACLY-managed file inside application documents.
  managed,

  /// Proven outside ORACLY's managed naming/location (external/gallery).
  notManaged,

  /// Ownership could not be determined — never treat as external success.
  unknown,
}

abstract final class ManagedFilePath {
  ManagedFilePath._();

  /// Classifies [path] as managed only when basename starts with
  /// [filePrefix]_ and the path normalizes INSIDE [documents].
  /// Traversal such as `documents/../outside` is [notManaged].
  static Future<ManagedPathKind> classify(
    String path, {
    required String filePrefix,
    Directory? documents,
  }) async {
    try {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return ManagedPathKind.notManaged;
      final name = trimmed.replaceAll('\\', '/').split('/').last;
      if (!name.startsWith('${filePrefix}_')) {
        return ManagedPathKind.notManaged;
      }
      final docs = documents ?? await getApplicationDocumentsDirectory();
      final docsNorm = normalize(docs.absolute.path);
      final fileNorm = normalize(File(trimmed).absolute.path);
      if (!isStrictlyInside(docsNorm, fileNorm)) {
        return ManagedPathKind.notManaged;
      }
      return ManagedPathKind.managed;
    } catch (_) {
      return ManagedPathKind.unknown;
    }
  }

  /// Whether [child] normalizes strictly inside [parent] (not equal).
  static bool isStrictlyInside(String parent, String child) {
    if (child == parent) return false;
    final prefix = parent.endsWith('/') ? parent : '$parent/';
    return child.startsWith(prefix);
  }

  /// Collapse `.` / `..` so `docs/../outside` cannot masquerade as inside.
  static String normalize(String raw) {
    final isUnc = raw.startsWith(r'\\') || raw.startsWith('//');
    final s = raw.replaceAll('\\', '/');
    final parts = <String>[];
    for (final segment in s.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(segment);
    }
    if (parts.isEmpty) return isUnc ? '//' : '/';
    if (isUnc) return '//${parts.join('/')}';
    if (raw.startsWith('/') &&
        parts.isNotEmpty &&
        !RegExp(r'^[A-Za-z]:').hasMatch(parts.first)) {
      return '/${parts.join('/')}';
    }
    return parts.join('/');
  }
}
