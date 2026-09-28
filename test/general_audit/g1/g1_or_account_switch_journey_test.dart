/// G1 Audit.1 — owner A has a pending OR handoff and a reply in flight when
/// the account switches: B's real OR chamber opens clean and B can talk.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/companion/services/companion_owner_guard.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:oracly_new/features/privacy/services/privacy_data_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';
import 'g1_or_support.dart';

const _aMessage = 'A PRIVATE MESSAGE FROM OWNER A';
const _aReply = 'A PRIVATE REPLY FOR OWNER A';

void main() {
  setUp(() {
    OraclyL10n.bind('en');
    OrChatHandoffBuffer.clear();
  });
  tearDown(OrChatHandoffBuffer.clear);

  testWidgets('pending handoff and in-flight reply never reach B; B talks '
      'normally', (tester) async {
    SharedPreferences.setMockInitialValues(
      {UserLocalDataIsolation.ownerKey: 'owner-a'},
    );
    final storage = await LocalStorage.open();
    String? auth = 'owner-a';
    final ai = G1ScriptedAi(
      replies: const [_aReply, 'B REPLY'],
      hold: Completer(),
    );
    final companion = g1Companion(
      ai: ai,
      repo: LocalAiConversationRepository(storage),
      storage: storage,
      ownerGuard: CompanionOwnerGuard.fromStorage(
        storage,
        liveOwnerId: () => auth,
      ),
    );
    String raw() =>
        (storage.getStringList('ai_conversations') ?? const []).join('\n');

    companion.applyReadingHandoff(g1CoffeeOwnerA);
    final pending = companion.send(_aMessage);
    OrChatHandoffBuffer.offer(g1CoffeeOwnerA);

    await tester.pumpWidget(buildProviderScopeHarness(
      storage: storage,
      overrides: [companionControllerProvider.overrideWith((ref) => companion)],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Column(
            children: [
              TextButton(
                onPressed: () => PrivacyDataRefresh.afterAccountSwitch(ref),
                child: const Text('switch'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CompanionReferenceScreen(),
                )),
                child: const Text('open OR'),
              ),
            ],
          ),
        ),
      ),
    ));
    expect(ai.calls, 1, reason: 'A reply is in flight');

    // Real order: Firebase moves first, the wipe runs, then the owner commits.
    auth = 'owner-b';
    await storage.setStringList('ai_conversations', const []);
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    await tester.tap(find.text('switch'));
    await tester.pump();

    ai.hold!.complete();
    await tester.pump();
    await pending;

    await tester.tap(find.text('open OR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    expect(companion.readingContext, isNull);
    expect(
      companion.state.context?.proactiveAcknowledgment ?? '',
      isNot(contains('OWNER A')),
    );
    expect(find.textContaining('OWNER A'), findsNothing);
    expect(find.text(OraclyL10n.t('or.handoff.arrive.coffee')), findsNothing);
    expect(OrChatHandoffBuffer.take(), isNull);
    expect(raw(), isNot(contains(_aMessage)));
    expect(raw(), isNot(contains(_aReply)));

    await companion.send('B MESSAGE');
    await tester.pump(const Duration(seconds: 2));

    expect(raw(), contains('B MESSAGE'));
    expect(raw(), contains('B REPLY'));
    expect(raw(), isNot(contains('OWNER A')));
    expect(companion.state.errorMessage, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
