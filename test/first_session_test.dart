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
    test('uses one quiet intro without a premium pitch', () {
      expect(OnboardingCopy.pages, hasLength(1));
      expect(OnboardingCopy.title, 'ORACLY');
      expect(
        OnboardingCopy.tagline,
        'Kendini farklı pencerelerden keşfet.',
      );
      expect(
        OnboardingCopy.pages.any((p) => p.title.contains('Premium')),
        isFalse,
      );
      expect(
        OnboardingCopy.startFirstReading.toLowerCase(),
        isNot(contains('premium')),
      );
      expect(
        OnboardingCopy.startFirstReading.toLowerCase(),
        isNot(contains('kart')),
      );
      final intro =
          '${OnboardingCopy.title} ${OnboardingCopy.tagline} '
          '${OnboardingCopy.windows.join(' ')}';
      expect(intro.toLowerCase(), isNot(contains('mücevher')));
      expect(intro.toLowerCase(), isNot(contains('premium')));
      expect(OnboardingCopy.meetLabel, isNot(OnboardingCopy.startFirstReading));
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
      expect(
        FirstSessionCopy.cardSelectionTitleFor(isFirstSession: true),
        FirstSessionCopy.cardSelectionTitle,
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
    test('persists pending first reading across restart', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      await FirstSessionIntent.requestFirstReading(storage);
      expect(FirstSessionIntent.isPending(storage), isTrue);

      final restarted = LocalStorage(await SharedPreferences.getInstance());
      expect(FirstSessionIntent.isPending(restarted), isTrue);
      expect(
        await FirstSessionIntent.consumePendingFirstReading(restarted),
        isTrue,
      );
      expect(
        await FirstSessionIntent.consumePendingFirstReading(restarted),
        isFalse,
      );
      expect(FirstSessionIntent.isPending(restarted), isFalse);
    });
  });
}
