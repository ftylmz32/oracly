/// Oracle Core NextAction MVP - evidence, dismiss, same-day, multi-feature.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/oracle_core/data/oracle_next_action_memory.dart';
import 'package:oracly_new/features/oracle_core/models/oracle_next_action_event.dart';
import 'package:oracly_new/features/oracle_core/models/oracle_next_action_reason.dart';
import 'package:oracly_new/features/oracle_core/models/oracle_premium_opportunity.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_next_action_copy.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_next_action_engine.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_next_action_evidence.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_recommended_feature.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import '../personal_discovery/pde_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  final now = DateTime(2026, 8, 16, 12);

  test('no recommendation without real multi-feature evidence', () {
    final empty = OracleNextActionEngine.decide(
      PersonalDiscoveryProfileBuilder.from(const PersonalDiscoverySources()),
      now: now,
    );
    expect(empty, isNull);

    final single = OracleNextActionEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Büyük bir değişim geliyor.', at: DateTime(2026, 8, 15)),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(single, isNull);
  });

  test('two different features with same theme yield one OR NextAction', () {
    final action = OracleNextActionEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Hayatımda değişim var.', at: DateTime(2026, 8, 12)),
          ],
          coffee: [
            pdeCoffee('c1', 'Fincanda değişim izi duruyor.', at: DateTime(2026, 8, 14)),
          ],
          conversations: [
            pdeOr('o1', 'Bu değişim hissi yumuşak.', at: DateTime(2026, 8, 15)),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(action, isNotNull);
    expect(action!.recommendedFeature, DiscoveryRecommendedFeature.companion);
    expect(action.reasonType, OracleNextActionReason.reflectWithOr);
    expect(action.theme, 'değişim');
    expect(action.hasEvidence, isTrue);
    expect(action.sourceFeatures, containsAll(['tarot', 'coffee', 'reflection']));
    expect(action.evidenceIds.length, greaterThanOrEqualTo(2));
    expect(action.premiumOpportunity, OraclePremiumOpportunity.none);
    final line = OracleNextActionCopy.line(action);
    expect(line, contains('OR'));
  });

  test('evidence ids resolve back to observation fingerprints', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('t1', 'Bir değişim dönemi.', at: DateTime(2026, 8, 12)),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim sakin ilerliyor.', at: DateTime(2026, 8, 14)),
        ],
      ),
      now: now,
    );
    final action = OracleNextActionEngine.decide(profile, now: now);
    expect(action, isNotNull);
    final expected = OracleNextActionEvidence.idsForTheme(
      profile.observations,
      action!.theme,
    );
    expect(action.evidenceIds, expected.take(action.evidenceIds.length).toList());
    for (final id in action.evidenceIds) {
      expect(id.contains('|'), isTrue);
      expect(
        id.startsWith('tarot|') || id.startsWith('coffee|'),
        isTrue,
      );
    }
  });

  test('same day shown blocks a second identical NextAction', () async {
    final memory = OracleNextActionMemory(LocalStorage.ephemeral());
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('t1', 'Değişim yakın.', at: DateTime(2026, 8, 12)),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim izi.', at: DateTime(2026, 8, 14)),
        ],
      ),
      now: now,
    );
    final first = OracleNextActionEngine.decide(
      profile,
      memory: memory,
      now: now,
    );
    expect(first, isNotNull);
    await memory.record(
      OracleNextActionEvent(
        theme: first!.theme,
        feature: first.recommendedFeature.name,
        at: now,
        kind: 'shown',
        evidenceIds: first.evidenceIds,
      ),
    );
    final second = OracleNextActionEngine.decide(
      profile,
      memory: memory,
      now: now.add(const Duration(hours: 3)),
    );
    expect(second, isNull);
  });

  test('dismiss cooldown blocks re-offer of the same theme action', () async {
    final memory = OracleNextActionMemory(LocalStorage.ephemeral());
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('t1', 'Değişim yakın.', at: DateTime(2026, 8, 12)),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim izi.', at: DateTime(2026, 8, 14)),
        ],
      ),
      now: now,
    );
    final first = OracleNextActionEngine.decide(
      profile,
      memory: memory,
      now: now,
    );
    expect(first, isNotNull);
    await memory.record(
      OracleNextActionEvent(
        theme: first!.theme,
        feature: first.recommendedFeature.name,
        at: now,
        kind: 'dismissed',
        evidenceIds: first.evidenceIds,
      ),
    );
    final blocked = OracleNextActionEngine.decide(
      profile,
      memory: memory,
      now: now.add(const Duration(days: 1)),
    );
    expect(blocked, isNull);

    final later = OracleNextActionEngine.decide(
      profile,
      memory: memory,
      now: now.add(const Duration(days: 15)),
    );
    expect(later, isNotNull);
  });


  test('journeyDepth opportunity when many cross-feature sightings exist', () {
    final action = OracleNextActionEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Hayatımda değişim var.', at: DateTime(2026, 8, 10)),
            pdeTarot('t2', 'Yine bir değişim dönemi.', at: DateTime(2026, 8, 12)),
          ],
          coffee: [
            pdeCoffee('c1', 'Fincanda değişim izi.', at: DateTime(2026, 8, 14)),
          ],
          conversations: [
            pdeOr('o1', 'Bu değişim hissi yumuşak.', at: DateTime(2026, 8, 15)),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(action, isNotNull);
    expect(action!.premiumOpportunity, OraclePremiumOpportunity.journeyDepth);
    expect(action.occurrenceCount, greaterThanOrEqualTo(4));
  });

  test('does not recommend OR if OR was already used today', () {
    final action = OracleNextActionEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Değişim yakın.', at: DateTime(2026, 8, 12)),
          ],
          coffee: [
            pdeCoffee('c1', 'Değişim izi.', at: DateTime(2026, 8, 14)),
          ],
          conversations: [
            pdeOr('o1', 'Bugün değişim üzerine.', at: now),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(action, isNull);
  });
}
