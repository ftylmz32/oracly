/// Oracle Core → OR: message-relevant OBSERVATION, never history dump.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_next_action_engine.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_or_context.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_or_privacy.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_or_style_hint.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import '../personal_discovery/pde_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  final now = DateTime(2026, 8, 16, 12);

  final profile = PersonalDiscoveryProfileBuilder.from(
    PersonalDiscoverySources(
      readings: [
        pdeTarot('t1', 'Hayatımda değişim var.', at: DateTime(2026, 8, 12)),
      ],
      coffee: [
        pdeCoffee(
          'c1',
          'Fincanda değişim izi duruyor.',
          at: DateTime(2026, 8, 14),
        ),
      ],
    ),
    now: now,
  );

  test('irrelevant message yields no Oracle Core OR context', () {
    final next = OracleNextActionEngine.decide(profile, now: now);
    expect(next, isNotNull);
    expect(
      OracleOrContext.forMessage(
        profile,
        'Bugün hava çok güzel.',
        nextAction: next,
        now: now,
      ),
      isNull,
    );
  });

  test('career/fear message uses değişim observation without raw readings', () {
    final next = OracleNextActionEngine.decide(profile, now: now);
    final hint = OracleOrContext.forMessage(
      profile,
      'İş değiştirmekten korkuyorum.',
      nextAction: next,
      now: now,
    );
    expect(hint, isNotNull);
    expect(hint!.toLowerCase(), contains('değişim'));
    expect(hint, contains('Tarot'));
    expect(hint, contains('Kahve'));
    expect(hint, isNot(contains('Hayatımda değişim var.')));
    expect(hint, isNot(contains('Fincanda değişim izi')));
    expect(hint, isNot(contains('/tmp/secret-cup.jpg')));
    expect(hint.length, lessThanOrEqualTo(OracleOrContext.maxChars));
  });

  test('privacy allowlist can block coffee evidence from OR', () {
    final next = OracleNextActionEngine.decide(profile, now: now);
    expect(
      OracleOrContext.forMessage(
        profile,
        'İş değiştirmekten korkuyorum.',
        nextAction: next,
        allowedSources: {'tarot'},
        now: now,
      ),
      isNull,
    );
    expect(OracleOrPrivacy.allows('coffee', {'tarot'}), isFalse);
  });

  test('styleHint tags OBSERVATION; feature handoff stays INTERPRETATION', () {
    final next = OracleNextActionEngine.decide(profile, now: now);
    final discovery = OracleOrStyleHint.forMessage(
      profile,
      'İş değiştirmekten korkuyorum.',
      nextAction: next,
      now: now,
    );
    expect(discovery, isNotNull);
    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'İş değiştirmekten korkuyorum.',
      recentMessages: const <ConversationTurn>[],
      discoveryHint: discovery,
      featureHandoff:
          'Tarot · Aşk yorumun: değişim teması yumuşak bir eşik gibi.',
    );
    expect(hint, contains('OBSERVATION'));
    expect(hint, contains('INTERPRETATION'));
    expect(hint.toLowerCase(), contains('değişim'));
    expect(hint, isNot(contains('Hayatımda değişim var.')));
  });
}
