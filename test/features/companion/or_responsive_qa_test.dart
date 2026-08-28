/// OR responsive QA — TECNO KN8 primary + portrait matrix.
///
/// Verifies header, messages, composer, keyboard, bottom nav clearance,
/// voice controls, paywall CTA reachability, and scrolling without overflow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_app_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_composer_dock.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_paywall.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_premium_dock.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thread.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_transcript_review.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_voice_slot.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_cta_unavailable.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_depth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TECNO KN8 (HD+ ~360 logical) + common Android portraits.
const _orViewports = <Size>[
  Size(360, 640), // short KN8-class
  Size(360, 720),
  Size(360, 800), // primary KN8
  Size(375, 812),
  Size(390, 844),
  Size(411, 901),
  Size(430, 932),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStorage> openStorage() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStorage.open();
  }

  Widget appShell({
    required Size size,
    required LocalStorage storage,
    required Widget child,
    double textScale = 1.0,
    double keyboard = 0,
    double bottomSafe = 24,
  }) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyAiServiceProvider.overrideWithValue(
          const UnconfiguredOraclyAiService(allowsLocalFallback: true),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: EdgeInsets.only(top: 28, bottom: bottomSafe),
            viewPadding: EdgeInsets.only(top: 28, bottom: bottomSafe),
            viewInsets: EdgeInsets.only(bottom: keyboard),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );
  }

  Future<void> pumpSized(
    WidgetTester tester,
    Size size,
    Widget child, {
    double textScale = 1.0,
    double keyboard = 0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await openStorage();
    await tester.pumpWidget(
      appShell(
        size: size,
        storage: storage,
        textScale: textScale,
        keyboard: keyboard,
        child: child,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  group('OR free chamber — KN8 portraits, zero overflow', () {
    for (final size in _orViewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('chamber $label', (tester) async {
        await pumpSized(tester, size, const CompanionReferenceScreen());
        expect(tester.takeException(), isNull);
        expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
        expect(find.text(CompanionCopy.orPremiumLead), findsOneWidget);
      });

      testWidgets('chamber $label textScale 1.3', (tester) async {
        await pumpSized(
          tester,
          size,
          const CompanionReferenceScreen(),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
      });
    }
  });

  group('OR paywall — CTA reachable, no clip', () {
    testWidgets('KN8 short: scroll reaches paywall action', (tester) async {
      const size = Size(360, 640);
      await pumpSized(tester, size, const CompanionReferenceScreen());
      expect(tester.takeException(), isNull);

      final list = find.byType(Scrollable);
      expect(list, findsWidgets);

      // Free preview embeds paywall; store-closed shows unavailable CTA.
      var action = find.byType(PremiumReferenceCtaUnavailable);
      if (action.evaluate().isEmpty) {
        action = find.text(CompanionCopy.orPaywallCta);
      }
      if (action.evaluate().isEmpty) {
        await tester.drag(list.first, const Offset(0, -2400));
        await tester.pumpAndSettle();
      }
      action = find.byType(PremiumReferenceCtaUnavailable);
      if (action.evaluate().isEmpty) {
        action = find.text(CompanionCopy.orPaywallCta);
      }
      expect(action, findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('premium dock CTA visible above nav clearance', (tester) async {
      const size = Size(360, 800);
      await pumpSized(
        tester,
        size,
        const Scaffold(
          body: Column(
            children: [
              Expanded(child: SizedBox.shrink()),
              CompanionReferenceOrPremiumDock(),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(CompanionCopy.orPaywallCta), findsOneWidget);
      final cta = tester.getRect(find.text(CompanionCopy.orPaywallCta));
      expect(cta.bottom, lessThanOrEqualTo(size.height));
      expect(cta.top, greaterThan(0));
    });

    testWidgets('inline paywall at 360 with textScale 1.3', (tester) async {
      const size = Size(360, 800);
      await pumpSized(
        tester,
        size,
        Scaffold(
          body: SingleChildScrollView(
            child: CompanionReferenceOrPaywall(
              entitlement: PremiumEntitlementState.inactive,
              purchaseConfigured: false,
              onPurchase: () {},
              onRestore: () {},
            ),
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumReferenceCtaUnavailable), findsOneWidget);
    });
  });

  group('OR composer + voice + keyboard', () {
    testWidgets('composer dock + keyboard on KN8 short', (tester) async {
      const size = Size(360, 640);
      final input = TextEditingController();
      addTearDown(input.dispose);
      await pumpSized(
        tester,
        size,
        Scaffold(
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              const Expanded(child: SizedBox.shrink()),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  reverse: true,
                  child: CompanionReferenceComposerDock(
                    inputController: input,
                    onSend: () {},
                    enabled: true,
                    onMicTap: () {},
                    onMicCancel: () {},
                    onPlusTap: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
        keyboard: 280,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CompanionReferenceInputBar), findsOneWidget);
      expect(find.byType(CompanionReferenceVoiceSlot), findsOneWidget);
      expect(find.text(ConversationCopy.inputHint), findsOneWidget);
    });

    testWidgets('input bar clears floating nav on KN8', (tester) async {
      const size = Size(360, 800);
      final input = TextEditingController();
      addTearDown(input.dispose);
      await pumpSized(
        tester,
        size,
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: CompanionReferenceInputBar(
              controller: input,
              onSend: () {},
              onMicTap: () {},
              onPlusTap: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // Outer InputBar includes bottom inset; assert the field sits above nav.
      final field = tester.getRect(find.byType(TextField));
      final clearance = AppLayout.floatingNavClearance(
        tester.element(find.byType(CompanionReferenceInputBar)),
      );
      expect(size.height - field.bottom, greaterThanOrEqualTo(clearance - 1));
    });

    testWidgets('voice chips + depth wrap at 360', (tester) async {
      const size = Size(360, 800);
      await pumpSized(
        tester,
        size,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CompanionReferenceOutputMode(
                  mode: OrChatOutputMode.conversation,
                  conversationAllowed: true,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                CompanionReferenceDepth(
                  depth: OrResponseDepth.balanced,
                  onChanged: (_) {},
                ),
                CompanionReferenceTranscriptReview(
                  visible: true,
                  onRetry: () {},
                  onConfirm: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(CompanionCopy.outputText), findsOneWidget);
      expect(find.text(CompanionCopy.outputVoice), findsOneWidget);
      expect(find.text(CompanionCopy.outputConversation), findsOneWidget);
      expect(find.text(CompanionCopy.voiceReviewSend), findsOneWidget);
    });
  });

  group('OR messages + scrolling', () {
    testWidgets('long thread scrolls without overflow on KN8', (tester) async {
      const size = Size(360, 800);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final messages = <AIMessage>[
        for (var i = 0; i < 12; i++)
          AIMessage(
            id: 'm$i',
            role: i.isEven ? AIMessageRole.user : AIMessageRole.assistant,
            content: i.isEven
                ? 'Kullanici mesaji $i — ${'x' * 40}'
                : 'OR yaniti $i. ${'Yansima. ' * 24}',
            createdAt: DateTime(2026, 1, 1, 0, i),
          ),
      ];
      await pumpSized(
        tester,
        size,
        Scaffold(
          body: CompanionReferenceThread(
            scrollController: scroll,
            messages: messages,
            showActions: true,
            allowSpeak: true,
            onSpeak: (_) {},
            onRegenerate: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CompanionReferenceMessageBubble), findsWidgets);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('header identity ellipsizes at 360 scale 1.3', (tester) async {
      const size = Size(360, 800);
      await pumpSized(
        tester,
        size,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(12),
            child: CompanionReferenceAppBar(),
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
    });
  });
}