/// RC-012 — First session tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/services/first_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingCopy', () {
    test('uses three calm slides without premium pitch', () {
      expect(OnboardingCopy.pages.length, 3);
      expect(
        OnboardingCopy.pages.any((p) => p.title.contains('Premium')),
        isFalse,
      );
      expect(OnboardingCopy.startFirstReading, contains('kart'));
    });

    test('explains what ORACLY is not', () {
      final last = OnboardingCopy.pages.last;
      expect(last.subtitle.toLowerCase(), contains('kehanet değil'));
    });
  });

  group('FirstSessionCopy', () {
    test('first session uses warmer guidance', () {
      expect(
        FirstSessionCopy.intentionSubtitleFor(isFirstSession: true),
        contains('zorunlu değil'),
      );
      expect(
        FirstSessionCopy.introPreparingFor(isFirstSession: true),
        contains('kehanet değil'),
      );
    });

    test('returning session keeps default ritual copy', () {
      expect(
        FirstSessionCopy.cardSelectionTitleFor(isFirstSession: false),
        FirstSessionCopy.cardSelectionTitleDefault,
      );
    });
  });

  group('FirstSessionService', () {
    test('detects empty history as first session', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = FirstSessionService(MockHistoryRepository(storage));
      expect(await service.isFirstSession(), isTrue);
    });
  });

  group('FirstSessionIntent', () {
    test('consumes pending first reading once', () {
      FirstSessionIntent.requestFirstReading();
      expect(FirstSessionIntent.consumePendingFirstReading(), isTrue);
      expect(FirstSessionIntent.consumePendingFirstReading(), isFalse);
    });
  });
}
