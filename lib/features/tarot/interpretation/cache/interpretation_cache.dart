/// OR-1180 — Local interpretation cache.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/data/datasources/local_storage.dart';
import '../models/interpretation_result.dart';

abstract class InterpretationCache {
  Future<InterpretationResult?> get(String cacheKey);
  Future<void> set(String cacheKey, InterpretationResult result);
  Future<void> invalidate(String cacheKey);
  Future<void> invalidateSession(String sessionId);
}

class LocalInterpretationCache implements InterpretationCache {
  LocalInterpretationCache(this._storage);

  final LocalStorage _storage;
  static const _prefix = 'or_tarot_interpretation_';

  String _key(String cacheKey) => '$_prefix$cacheKey';

  @override
  Future<InterpretationResult?> get(String cacheKey) async {
    final raw = _storage.getString(_key(cacheKey));
    if (raw == null || raw.isEmpty) return null;
    try {
      final result = InterpretationResult.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return result.copyWith(fromCache: true, source: InterpretationSource.cache);
    } catch (error) {
      assert(() {
        debugPrint('[InterpretationCache] Corrupt cache entry discarded');
        return true;
      }());
      await invalidate(cacheKey);
      return null;
    }
  }

  @override
  Future<void> set(String cacheKey, InterpretationResult result) async {
    await _storage.setString(_key(cacheKey), jsonEncode(result.toJson()));
  }

  @override
  Future<void> invalidate(String cacheKey) async {
    await _storage.setString(_key(cacheKey), '');
  }

  @override
  Future<void> invalidateSession(String sessionId) async {
    // Session-scoped keys include sessionId — full sweep via prefix not available;
    // callers pass explicit cacheKey from ReadingContext.
    await invalidate('interp_$sessionId');
  }
}
