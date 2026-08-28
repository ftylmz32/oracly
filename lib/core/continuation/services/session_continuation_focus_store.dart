/// One-shot theme focus when crossing from one chamber to another.

library;



import 'dart:convert';



import '../../data/datasources/local_storage.dart';

import '../models/session_continuation.dart';



class SessionContinuationFocus {

  const SessionContinuationFocus({

    required this.target,

    this.theme,

  });



  final SessionContinuationTarget target;

  final String? theme;

}



class SessionContinuationFocusStore {

  SessionContinuationFocusStore(this._storage);



  static const key = 'session_continuation_focus_v1';



  final LocalStorage _storage;



  SessionContinuationFocus? peek() {

    final raw = _storage.getString(key);

    if (raw == null || raw.isEmpty) return null;

    try {

      final json = jsonDecode(raw) as Map<String, dynamic>;

      final target = SessionContinuationTarget.values.byName('${json['target']}');

      final theme = '${json['theme'] ?? ''}'.trim();

      return SessionContinuationFocus(

        target: target,

        theme: theme.isEmpty ? null : theme,

      );

    } catch (_) {

      return null;

    }

  }



  Future<void> write(SessionContinuation item) async {

    final theme = item.theme?.trim();

    await _storage.setString(

      key,

      jsonEncode({

        'target': item.target.name,

        if (theme != null && theme.isNotEmpty) 'theme': theme,

      }),

    );

  }



  SessionContinuationFocus? consumeFor(SessionContinuationTarget target) {

    final value = peek();

    if (value == null || value.target != target) return null;

    clear();

    return value;

  }



  Future<void> clear() => _storage.remove(key);

}


