/// Cross-discovery OR context — compact, relevant, never fabricated.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/personal_discovery/services/or_cross_discovery_context.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import 'pde_test_fixtures.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));
  final now = DateTime(2026, 8, 19);

  test('empty history invents nothing', () {
    expect(
      OrCrossDiscoveryContext.forMessage(
        PersonalDiscoveryProfileBuilder.from(
          const PersonalDiscoverySources(),
          now: now,
        ),
        'İş konusunda ne dersin?',
      ),
      isNull,
    );
  });

  test('single sighting is not a connection', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [pdeCoffee('c1', 'Kariyer yolunda ilerlemek gerekiyor.', at: now)],
      ),
      now: now,
    );
    expect(
      OrCrossDiscoveryContext.forMessage(profile, 'İş konusunda ne dersin?'),
      isNull,
    );
  });

  test('real cross-chamber theme stays compact and names areas', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'İş hayatında karar vermek zor.', at: now),
          pdeTarot('r2', 'Kariyer yolunda netleşme var.', at: now),
        ],
        coffee: [
          pdeCoffee('c1', 'Meslek alanında ilerlemek gerekiyor.', at: now),
        ],
        palm: [
          pdePalm('p1', 'Kariyer çizgisinde ilerleme izi var.', at: now),
        ],
        astrology: [
          pdeSky('a1', 'İş ve kariyer temposu ölçülü.', at: now),
        ],
      ),
      now: now,
    );
    final hint = OrCrossDiscoveryContext.forMessage(
      profile,
      'İş konusunda ne düşünüyorsun?',
    );
    expect(hint, isNotNull);
    expect(hint!.length, lessThanOrEqualTo(OrCrossDiscoveryContext.maxChars));
    expect(hint.toLowerCase(), anyOf(contains('kariyer'), contains('iş')));
    expect(hint, contains('Gözlenen alanlar:'));
    expect(hint, isNot(contains('secret-cup')));
    expect(hint.toLowerCase(), isNot(contains('14 gün')));
    // No fabricated dump of full readings.
    expect(hint, isNot(contains('netleşme var')));
  });

  test('irrelevant message gets silence', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Karar vermek zor.', at: now),
          pdeTarot('r2', 'Bu karar alma süreci netleşiyor.', at: now),
        ],
        coffee: [pdeCoffee('c1', 'Karar verip ilerlemek gerekiyor.')],
      ),
      now: now,
    );
    expect(
      DiscoveryOrContext.compactForMessage(profile, 'Bugün hava nasıl?'),
      isNull,
    );
  });

  test('chamber mention can surface a real repeating theme', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Değişim ve dönüşüm kapıda.', at: now),
          pdeTarot('r2', 'Hareket ve geçiş var.', at: now),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim rüzgarı esiyor.', at: now),
        ],
      ),
      now: now,
    );
    final hint = OrCrossDiscoveryContext.forMessage(
      profile,
      'Kahve falım hakkında konuşalım.',
    );
    expect(hint, isNotNull);
    expect(hint!.toLowerCase(), contains('değişim'));
  });

  test('theme repeat in one chamber may be recognized when relevant', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Sınırlar koymak önemli.', at: now),
          pdeTarot('r2', 'Sınırlarını koru ve net ol.', at: now),
          pdeTarot('r3', 'Sınır teması yeniden görünüyor.', at: now),
        ],
      ),
      now: now,
    );
    final hint = OrCrossDiscoveryContext.forMessage(
      profile,
      'Sınırlar konusunda sıkışıyorum.',
    );
    expect(hint, isNotNull);
    expect(hint!.toLowerCase(), contains('sınır'));
    expect(hint, isNot(contains('Gözlenen alanlar:')));
  });
}
