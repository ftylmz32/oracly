/// Daily discovery suggestion — evidence only, never a random pick.
library;

import 'package:oracly_new/features/personal_discovery/copy/discovery_recommendation_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_recommend_kind.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_recommended_feature.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_recommendation_engine.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 16);

  test('empty profile recommends daily message without a reason', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(const PersonalDiscoverySources()),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.dailyMessage);
    expect(rec.kind, DiscoveryRecommendKind.empty);
    expect(rec.hasEvidence, isFalse);
    expect(DiscoveryRecommendationCopy.reason(rec), isNull);
    expect(
      DiscoveryRecommendationCopy.cta(rec.feature),
      'Bugünün mesajı',
    );
  });

  test('one source with no mapped theme follows that source', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          dreams: [pdeDream('d1', 'Denizde yürüdüm.', at: DateTime(2026, 8, 15))],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.dream);
    expect(rec.kind, DiscoveryRecommendKind.source);
    expect(rec.source, 'dream');
    expect(
      DiscoveryRecommendationCopy.cta(rec.feature),
      'Rüyanı yorumla',
    );
    expect(DiscoveryRecommendationCopy.reason(rec), contains('rüya'));
  });

  test('two sources prefer a different chamber than the latest', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          coffee: [
            pdeCoffee('c1', 'Fincan sakin duruyor.', at: DateTime(2026, 8, 10)),
          ],
          dreams: [
            pdeDream('d1', 'Denizde yürüdüm.', at: DateTime(2026, 8, 15)),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.coffee);
    expect(rec.source, 'coffee');
  });

  test('recent relationship theme recommends yıldızname', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          coffee: [
            pdeCoffee(
              'c1',
              'Bu ilişki sakin tutulsun.',
              at: DateTime(2026, 8, 14),
            ),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.starMap);
    expect(rec.theme, 'ilişki');
    expect(
      DiscoveryRecommendationCopy.cta(rec.feature),
      "Yıldızname'ni keşfet",
    );
  });

  test('recurring decision theme recommends talking with OR', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          coffee: [
            pdeCoffee(
              'c1',
              'Karar vermek için durul.',
              at: DateTime(2026, 8, 12),
            ),
            pdeCoffee(
              'c2',
              'Karar alma yumuşak olsun.',
              at: DateTime(2026, 8, 14),
            ),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.companion);
    expect(rec.kind, DiscoveryRecommendKind.theme);
    expect(rec.theme, 'karar verme');
    expect(rec.recurring, isTrue);
    expect(
      DiscoveryRecommendationCopy.cta(rec.feature),
      "OR'a danış",
    );
    expect(DiscoveryRecommendationCopy.reason(rec), contains('Karar verme'));
    expect(DiscoveryRecommendationCopy.reason(rec), contains('tekrar'));
  });

  test('recent theme beats an older relationship theme', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          coffee: [
            pdeCoffee(
              'old',
              'Bu ilişki sakin tutulsun.',
              at: DateTime(2026, 6, 1),
            ),
            pdeCoffee(
              'old2',
              'İlişki teması duruyor.',
              at: DateTime(2026, 6, 2),
            ),
          ],
          dreams: [
            pdeDream(
              'd1',
              'Karar vermek istiyorum.',
              at: DateTime(2026, 8, 15),
            ),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.companion);
    expect(rec.theme, 'karar verme');
    expect(rec.feature, isNot(DiscoveryRecommendedFeature.starMap));
  });

  test('stale history without recent evidence stays the daily message', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          coffee: [
            pdeCoffee('old', 'Sakin fincan.', at: DateTime(2026, 5, 1)),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.dailyMessage);
    expect(rec.hasEvidence, isFalse);
    expect(DiscoveryRecommendationCopy.reason(rec), isNull);
  });

  test('same inputs yield the same chamber — never a lottery', () {
    final sources = PersonalDiscoverySources(
      dreams: [pdeDream('d1', 'Denizde yürüdüm.', at: DateTime(2026, 8, 15))],
      coffee: [
        pdeCoffee('c1', 'Fincan sakin duruyor.', at: DateTime(2026, 8, 10)),
      ],
    );
    final a = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(sources, now: now),
      now: now,
    );
    final b = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(sources, now: now),
      now: now,
    );
    expect(a.feature, b.feature);
    expect(a.kind, b.kind);
    expect(a.source, b.source);
  });

  test('copy never exposes scoring internals', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          dreams: [pdeDream('d1', 'Denizde yürüdüm.', at: DateTime(2026, 8, 15))],
        ),
        now: now,
      ),
      now: now,
    );
    final blob =
        '${DiscoveryRecommendationCopy.title} '
        '${DiscoveryRecommendationCopy.cta(rec.feature)} '
        '${DiscoveryRecommendationCopy.reason(rec)}';
    expect(blob.toLowerCase(), isNot(contains('score')));
    expect(blob, isNot(contains('recencyWeight')));
    expect(blob, isNot(contains('0.85')));
  });

  test('unavailable recent source falls through without inventing a theme', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          dreams: [pdeDream('d1', 'Denizde yürüdüm.', at: DateTime(2026, 8, 15))],
        ),
        now: now,
      ),
      now: now,
      available: {
        DiscoveryRecommendedFeature.dailyMessage,
        DiscoveryRecommendedFeature.coffee,
      },
    );
    expect(rec.feature, DiscoveryRecommendedFeature.dailyMessage);
    expect(rec.hasEvidence, isFalse);
  });

  test('strong recent tarot recommends a new spread', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Sakin bir bakış.', at: DateTime(2026, 8, 12)),
            pdeTarot('t2', 'Sakin duruş.', at: DateTime(2026, 8, 15)),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.tarot);
    expect(rec.kind, DiscoveryRecommendKind.source);
    expect(rec.source, 'tarot');
    expect(rec.evidenceCount, 2);
    expect(DiscoveryRecommendationCopy.cta(rec.feature), 'Yeni bir açılım');
    expect(
      DiscoveryRecommendationCopy.reason(rec),
      contains('tarot çekimlerin sıklaştığı'),
    );
  });

  test('two recent dreams use the rise reason only when true', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          dreams: [
            pdeDream('d1', 'Denizde yürüdüm.', at: DateTime(2026, 8, 14)),
            pdeDream('d2', 'Yine deniz vardı.', at: DateTime(2026, 8, 15)),
          ],
        ),
        now: now,
      ),
      now: now,
    );
    expect(rec.feature, DiscoveryRecommendedFeature.dream);
    expect(rec.evidenceCount, 2);
    expect(
      DiscoveryRecommendationCopy.reason(rec),
      'Son günlerde rüya temaların arttığı için.',
    );
  });

  test('one dream does not claim that dream themes increased', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          dreams: [pdeDream('d1', 'Denizde yürüdüm.', at: DateTime(2026, 8, 15))],
        ),
        now: now,
      ),
      now: now,
    );
    expect(DiscoveryRecommendationCopy.reason(rec), isNot(contains('arttığı')));
  });

  test('completed tarot today is not recommended again', () {
    final rec = DiscoveryRecommendationEngine.decide(
      PersonalDiscoveryProfileBuilder.from(
        PersonalDiscoverySources(
          readings: [
            pdeTarot('t1', 'Sakin bir bakış.', at: DateTime(2026, 8, 16, 9)),
          ],
        ),
        now: DateTime(2026, 8, 16, 18),
      ),
      now: DateTime(2026, 8, 16, 18),
    );
    expect(rec.feature, isNot(DiscoveryRecommendedFeature.tarot));
    expect(rec.hasEvidence, isFalse);
    expect(DiscoveryRecommendationCopy.reason(rec), isNull);
  });
}
