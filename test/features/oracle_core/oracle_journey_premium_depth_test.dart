/// Journey Premium depth — honest gates, no fake scarcity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/oracle_core/models/oracle_premium_opportunity.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_journey_archive_builder.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_journey_depth_gate.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_journey_premium_copy.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_next_action_engine.dart';
import 'package:oracly_new/features/oracle_core/services/oracle_or_context.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/premium/services/premium_feature_gates.dart';

import '../personal_discovery/pde_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  final now = DateTime(2026, 8, 26, 12);

  PersonalDiscoveryProfile deepProfile() => PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Hayatımda değişim var.', at: DateTime(2026, 8, 10)),
            pdeTarot('t2', 'Yine bir değişim dönemi.', at: DateTime(2026, 8, 12)),
          ],
          coffee: [
            pdeCoffee('c1', 'Fincanda değişim izi.', at: DateTime(2026, 8, 14)),
          ],
          conversations: [
            pdeOr('o1', 'Bu değişim hissi yumuşak.', at: DateTime(2026, 8, 20)),
          ],
        ),
        now: now,
      );

  PersonalDiscoveryProfile basicProfile() => PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Hayatımda değişim var.', at: DateTime(2026, 8, 12)),
          ],
          coffee: [
            pdeCoffee('c1', 'Fincanda değişim izi.', at: DateTime(2026, 8, 14)),
          ],
        ),
        now: now,
      );

  test('free keeps basic NextAction; soft invite only when journeyDepth real', () {
    final basic = OracleNextActionEngine.decide(basicProfile(), now: now)!;
    expect(basic.premiumOpportunity, OraclePremiumOpportunity.none);
    final freeBasic = OracleJourneyDepthGate.resolve(
      opportunity: basic.premiumOpportunity,
      hasEvidence: true,
      isPremium: false,
    );
    expect(freeBasic.allowBasicNextAction, isTrue);
    expect(freeBasic.allowSoftPremiumInvite, isFalse);
    expect(freeBasic.allowJourneyArchive, isFalse);

    final deep = OracleNextActionEngine.decide(deepProfile(), now: now)!;
    expect(deep.premiumOpportunity, OraclePremiumOpportunity.journeyDepth);
    final freeDeep = OracleJourneyDepthGate.resolve(
      opportunity: deep.premiumOpportunity,
      hasEvidence: true,
      isPremium: false,
      journeyReady: true,
    );
    expect(freeDeep.allowBasicNextAction, isTrue);
    expect(freeDeep.allowSoftPremiumInvite, isTrue);
    expect(freeDeep.allowJourneyArchive, isFalse);
    expect(freeDeep.allowDeepOrContext, isFalse);
  });

  test('premium unlocks archive and deep OR without soft invite', () {
    final deep = OracleNextActionEngine.decide(deepProfile(), now: now)!;
    final access = OracleJourneyDepthGate.resolve(
      opportunity: deep.premiumOpportunity,
      hasEvidence: true,
      isPremium: true,
      journeyReady: true,
    );
    expect(access.allowSoftPremiumInvite, isFalse);
    expect(access.allowJourneyArchive, isTrue);
    expect(access.allowDeepOrContext, isTrue);
    expect(access.allowThemeHistory, isTrue);

    final archive = OracleJourneyArchiveBuilder.fromProfile(
      deepProfile(),
      now: now,
    );
    expect(archive, isNotNull);
    expect(archive!.isNotEmpty, isTrue);
    expect(archive.entries.first.isCrossFeature, isTrue);
  });

  test('no evidence means no soft invite and no archive bait', () {
    final access = OracleJourneyDepthGate.resolve(
      opportunity: OraclePremiumOpportunity.none,
      hasEvidence: false,
      isPremium: false,
      journeyReady: false,
    );
    expect(access.allowSoftPremiumInvite, isFalse);
    expect(access.allowBasicNextAction, isFalse);
    expect(
      OracleJourneyArchiveBuilder.fromProfile(
        PersonalDiscoveryProfile.empty,
        now: now,
      ),
      isNull,
    );
  });

  test('soft copy is honest — no fear, no solve-with-premium', () {
    final deep = OracleNextActionEngine.decide(deepProfile(), now: now)!;
    final body = OracleJourneyPremiumCopy.softBody(deep).toLowerCase();
    expect(body, contains('premium'));
    expect(body, contains('temel gözlemin'));
    expect(body, isNot(contains('kork')));
    expect(body, isNot(contains('çözmek için')));
    expect(body, isNot(contains('kaçırma')));
  });

  test('deep OR adds comparison only with real time span', () {
    final profile = deepProfile();
    final next = OracleNextActionEngine.decide(profile, now: now);
    final basic = OracleOrContext.forMessage(
      profile,
      'değişim hakkında düşünüyorum',
      nextAction: next,
      now: now,
    );
    final deep = OracleOrContext.forMessage(
      profile,
      'değişim hakkında düşünüyorum',
      nextAction: next,
      now: now,
      deep: true,
    );
    expect(basic, isNotNull);
    expect(deep, isNotNull);
    expect(deep!.length, greaterThanOrEqualTo(basic!.length));
    expect(deep.toLowerCase(), contains('karşılaştırma'));
  });

  test('premium gates list journey depth capabilities', () {
    expect(
      PremiumFeatureGates.capabilityRequiresPremium(
        PremiumGatedCapability.journeyArchive,
      ),
      isTrue,
    );
    expect(
      PremiumFeatureGates.capabilityRequiresPremium(
        PremiumGatedCapability.orJourneyContext,
      ),
      isTrue,
    );
  });
}
