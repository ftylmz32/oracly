/// Product Completion Batch 1 — Premium override, Dream sections, Explore, OR.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/services/companion_followup_chips.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_composer.dart';
import 'package:oracly_new/features/dream/services/dream_reading_presentation.dart';
import 'package:oracly_new/features/explore/presentation/explore_reference_screen.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/soul_mate_dev_access.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  tearDown(PremiumDevOverride.resetDebug);

  group('DEV Premium override', () {
    test('development + flag unlocks; production ignores', () {
      PremiumDevOverride.debugEnvironment = AppEnvironment.development;
      PremiumDevOverride.debugFlag = true;
      expect(PremiumDevOverride.isActive, isTrue);
      expect(SoulMateDevAccess.allowsTestAccess, isTrue);

      PremiumDevOverride.debugFlag = false;
      expect(PremiumDevOverride.isActive, isFalse);

      PremiumDevOverride.debugEnvironment = AppEnvironment.production;
      PremiumDevOverride.debugFlag = true;
      expect(PremiumDevOverride.isActive, isFalse);
    });
  });

  group('Dream sections', () {
    test('AI fields map into editorial section cards', () {
      const narrative =
          'Rüyamda uzun bir yılan evden geçti ve sessizce gitti.';
      final understanding = DreamUnderstandingService().build(narrative: narrative);
      final dream = Dream(
        id: 'd1',
        narrative: narrative,
        recordedAt: DateTime(2026, 1, 1),
        understanding: understanding,
      );
      const ai = DreamAiAnalysis(
        summary: 'Bu ruya bir gecis hissi tasiyor, acele yok.',
        symbols: ['yilan', 'ev'],
        emotionalTheme: 'Belirsizlik ve yenilenme yumusakca birlikte.',
        interpretation: 'Yılan burada tehdit değil; geçiş izi olabilir.',
        dailyLifeReflection:
            'Bugün yılanın sessiz geçişi gibi acele etmeden bir adım geri durmak iyi gelebilir.',
        conclusion:
            'Bu ruya bir uyari degil, bir davettir; neye davet ediliyor?',
      );
      final insights = DreamAnalysisComposer.compose(
        dream: dream,
        understanding: understanding,
        ai: ai,
      );
      final kinds = insights.map((e) => e.kind).toList();
      expect(kinds, contains(DreamInsightKind.summary));
      expect(kinds, contains(DreamInsightKind.symbols));
      expect(kinds, contains(DreamInsightKind.emotionalMeaning));
      expect(kinds, contains(DreamInsightKind.mainInterpretation));
      expect(kinds, contains(DreamInsightKind.personalConnection));
      expect(kinds, contains(DreamInsightKind.themes));
      expect(kinds, contains(DreamInsightKind.closingTakeaway));
      final interpretation = insights.firstWhere(
        (e) => e.kind == DreamInsightKind.mainInterpretation,
      );
      final life = insights.firstWhere(
        (e) => e.kind == DreamInsightKind.personalConnection,
      );
      expect(interpretation.body, contains('geçiş izi'));
      expect(life.body, contains('yılan'));
      expect(interpretation.body, isNot(equals(life.body)));
      final sections = DreamReadingPresentation.sections(
        dream.copyWith(insights: insights, fromAi: true),
      );
      expect(sections.length, greaterThanOrEqualTo(3));
      expect(kinds, contains(DreamInsightKind.themes));
    });
  });

  group('Explore hub', () {
    testWidgets('Kesfet root is Explore hub', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      OraclyL10n.bind('tr');
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: const MaterialApp(home: ExploreReferenceScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(ExploreReferenceScreen), findsOneWidget);
      expect(OraclyTab.astrology.index, 2);
    });
  });

  group('OR flagship copy', () {
    test('starter topics and dream handoff arrive line', () {
      OraclyL10n.bind('tr');
      expect(CompanionCopy.suggestions.length, greaterThanOrEqualTo(7));
      expect(
        OrChatHandoff.arrivalLine(
          const OracleReadingContext(
            kind: OracleReadingKind.dream,
            sessionId: 's',
            deckId: 'dream',
            deckName: 'dream',
            spreadLabel: '',
            readingTitle: '',
            cardsSummary: '',
            interpretationSummary: 'ozet',
          ),
        ),
        contains('yorumu burada'),
      );
    });
  });

  group('OR flagship consistency batch', () {
    test('oracle request sends turns and personality', () {
      final req = OpenAiServiceRequests.oracle(
        model: 'gpt-4o',
        context: const TarotAiContext(
          sessionId: 's1',
          spreadLabel: 'Tek',
          readingTitle: 'Bugun',
          cardsSummary: 'The Moon',
          interpretationSummary: 'Sis',
        ),
        userMessage: 'Bu kart bende neyi tetikliyor?',
        priorUser: const [],
        personality: 'direct',
        turns: [
          ConversationTurn.user('Acilimi anladim.'),
          ConversationTurn.assistant('Duraklama hissi one cikiyor.'),
        ],
      );
      final turns = req.payload['turns'] as List;
      expect(turns.last['role'], 'assistant');
      expect(req.payload['personality'], 'direct');
    });

    test('idle copy and follow-up chips', () {
      OraclyL10n.bind('tr');
      expect(CompanionCopy.idleTitle, contains('Akl'));
      expect(CompanionCopy.menuNewChat, 'Yeni bir konu');
      expect(CompanionCopy.menuRemoveReading, contains('sohbetten'));
      final chips = CompanionFollowUpChips.forTurn(
        lastUserMessage: 'Ne yapacagimi bilmiyorum',
        hasReadingContext: true,
      );
      expect(chips.last, contains('işaret'));
      expect(CompanionCopy.thinking, isNot(contains('OR dusunuyor')));
    });
  });
}
