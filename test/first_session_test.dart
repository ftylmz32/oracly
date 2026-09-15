/// RC-012 — First session tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/services/first_session_service.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
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

  group('isFirstSessionProvider refresh after Tarot completion', () {
    // Regression for the Soulmate prerequisite release blocker: a completed
    // daily Tarot reading changes the underlying history, but
    // isFirstSessionProvider is a cached FutureProvider -- without an
    // explicit invalidation, Soulmate would keep showing the "start with
    // today's free card" gate forever, even after the user just did it.
    test(
      'stays stale until invalidated, then reflects the new reading',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final container = ProviderContainer(
          overrides: [localStorageProvider.overrideWithValue(storage)],
        );
        addTearDown(container.dispose);

        expect(await container.read(isFirstSessionProvider.future), isTrue);

        await container.read(historyRepositoryProvider).saveReading(
          ReadingModel(
            id: 'r1',
            cardId: 0,
            cardName: 'The Sun',
            cardImageAsset: 'a',
            spreadType: 'Tek Kart',
            aiSummary: 'A free daily card reading.',
            createdAt: DateTime(2026, 9, 11),
          ),
        );

        // Proves the staleness this fix addresses: without invalidation the
        // cached value does not see the new reading.
        expect(await container.read(isFirstSessionProvider.future), isTrue);

        container.invalidate(isFirstSessionProvider);
        expect(await container.read(isFirstSessionProvider.future), isFalse);
      },
    );
  });
}
