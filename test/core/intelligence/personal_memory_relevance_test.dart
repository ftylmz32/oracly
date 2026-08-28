/// Personal memory relevance — OR context only when themes match the message.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_builder.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_or_copy.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_relevance.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import '../../features/personal_discovery/pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 19);

  test('irrelevant message gets no discovery hint', () {
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
      PersonalMemoryRelevance.hintForMessage(profile, 'Bugün hava nasıl?'),
      isNull,
    );
  });

  test('short or off-topic observation stays out of the prompt', () {
    const obs =
        'Son dönemde değişim konusu birkaç farklı keşfinde yeniden karşına çıkıyor.';
    expect(
      PersonalMemoryRelevance.filterObservation(obs, 'Selam'),
      isNull,
    );
    expect(
      PersonalMemoryRelevance.filterObservation(obs, 'Bugün hava nasıl acaba?'),
      isNull,
    );
    expect(
      PersonalMemoryRelevance.filterObservation(
        obs,
        'Değişimden korkuyorum biraz.',
      ),
      isNotNull,
    );
  });

  test('career message receives compact relevant hint', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'İş hayatında karar vermek zor.', at: now),
          pdeTarot('r2', 'Kariyer yolunda netleşme var.', at: now),
        ],
        coffee: [pdeCoffee('c1', 'Meslek alanında ilerlemek gerekiyor.')],
      ),
      now: now,
    );
    final hint = PersonalMemoryRelevance.hintForMessage(
      profile,
      'İş konusunda ne düşünüyorsun?',
    );
    expect(hint, isNotNull);
    expect(hint!.toLowerCase(), isNot(contains('14 gün')));
  });

  test('tension observation prefers change vs rest without identity claims', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Değişim ve dönüşüm kapıda.', at: now),
          pdeTarot('r2', 'Hareket ve geçiş var.', at: now.subtract(const Duration(days: 1))),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim rüzgarı esiyor.', at: now),
          pdeCoffee('c2', 'Dinlenmek ve yavaşlamak gerekiyor.', at: now),
        ],
        dreams: [
          pdeDream('d1', 'Nefes almak için mola ver.', at: now),
          pdeDream('d2', 'Sakinleşmek istiyorum.', at: now.subtract(const Duration(days: 1))),
        ],
      ),
      now: now,
    );
    final summary = PersonalMemoryBuilder.fromProfile(profile, now: now);
    final ids = summary.themes.map((t) => t.id).toSet();
    expect(ids, containsAll(['change', 'rest']));
    final line = PersonalMemoryOrCopy.tension(summary);
    expect(line, isNotNull);
    expect(line!.toLowerCase(), isNot(contains('korkan')));
    expect(line.toLowerCase(), isNot(contains('hep')));
  });
}
