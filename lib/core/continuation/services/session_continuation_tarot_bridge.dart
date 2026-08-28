/// Applies one-shot tarot continuation theme to the intention field.

library;



import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../../app/providers/app_providers.dart';

import '../models/session_continuation.dart';

import 'session_continuation_focus_store.dart';



abstract final class SessionContinuationTarotBridge {

  SessionContinuationTarotBridge._();



  static String? consumeThemeHint(WidgetRef ref) {

    final storage = ref.read(localStorageProvider);

    return SessionContinuationFocusStore(storage)

        .consumeFor(SessionContinuationTarget.tarot)

        ?.theme;

  }

}


