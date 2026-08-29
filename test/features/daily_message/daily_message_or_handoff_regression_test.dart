/// Regression: Daily Message "OR'a sor" already hands off typed daily context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/or_session_state.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:oracly_new/features/companion/services/or_session_resolver.dart';
import 'package:oracly_new/features/daily_message/copy/daily_message_copy.dart';
import 'package:oracly_new/features/daily_message/models/daily_message.dart';
import 'package:oracly_new/features/daily_message/models/daily_return_action.dart';
import 'package:oracly_new/features/daily_message/presentation/widgets/daily_return_cta.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    OrChatHandoffBuffer.clear();
  });

  tearDown(OrChatHandoffBuffer.clear);

  final day = DateTime(2026, 8, 29);
  const text = 'Bugun bir cumleyi yavas soyle.';
  const theme = 'sakinlik';
  final message = DailyMessage(
    text: text,
    day: day,
    theme: theme,
    action: DailyReturnAction.talkToOr,
    sunSign: 'Aslan',
  );

  testWidgets('OR\'a sor hands off dailyMessage context, not a null open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await FirstReadingOrDeepen.markEligible(storage, 'session_first');

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: _ShellHarness(
          child: DailyReturnCta(
            action: DailyReturnAction.talkToOr,
            message: message,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(DailyMessageCopy.talkToOr), findsOneWidget);
    expect(OrChatHandoffBuffer.take(), isNull);

    await tester.tap(find.text(DailyMessageCopy.talkToOr));
    await tester.pumpAndSettle();

    expect(find.text('or-tab'), findsOneWidget);

    final controller = ProviderScope.containerOf(
      tester.element(find.text('or-tab')),
    ).read(companionControllerProvider);

    final ctx = controller.readingContext;
    expect(ctx, isNotNull);
    expect(ctx!.kind, OracleReadingKind.dailyMessage);
    expect(ctx.sessionId, 'daily_${message.dateKey}');
    expect(ctx.fullInterpretation, contains(text));
    expect(ctx.fullInterpretation, contains(theme));
    expect(ctx.fullInterpretation, contains('Aslan'));
    expect(ctx.sourceLabel, contains('G'));
    expect(OrChatHandoffBuffer.take(), isNull);
  });

  test(
    'dailyMessage context never unlocks first-reading free deepen',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstReadingOrDeepen.markEligible(storage, 'session_first');
      expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);

      final ctx = OracleReadingContextSources.dailyMessage(
        text: text,
        dayKey: message.dateKey,
        theme: theme,
        sunSign: 'Aslan',
      );
      expect(ctx.kind, OracleReadingKind.dailyMessage);
      expect(ctx.sessionId, 'daily_${message.dateKey}');
      expect(FirstReadingOrDeepen.allows(storage, ctx), isFalse);

      final session = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        chamberEmpty: false,
        contextualDeepenAllowed: FirstReadingOrDeepen.allows(storage, ctx),
      );
      expect(session.canCompose, isFalse);
      expect(session.showPaywallDock, isTrue);
      expect(session.state, OrSessionState.free);
    },
  );

  test('dailyMessage buffer offer is one-shot', () {
    final expected = OracleReadingContextSources.dailyMessage(
      text: text,
      dayKey: message.dateKey,
      theme: theme,
      sunSign: 'Aslan',
    );
    OrChatHandoffBuffer.offer(expected);
    final taken = OrChatHandoffBuffer.take();
    expect(taken, isNotNull);
    expect(taken!.kind, OracleReadingKind.dailyMessage);
    expect(taken.sessionId, expected.sessionId);
    expect(taken.fullInterpretation, contains(text));
    expect(OrChatHandoffBuffer.take(), isNull);
  });
}

class _ShellHarness extends StatefulWidget {
  const _ShellHarness({required this.child});

  final Widget child;

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  int _tab = OraclyTab.home.index;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OraclyNavigationScope(
        currentIndex: _tab,
        switchToTab: (i) => setState(() => _tab = i),
        child: Scaffold(
          body: _tab == OraclyTab.home.index
              ? Center(child: widget.child)
              : const Text('or-tab'),
        ),
      ),
    );
  }
}
