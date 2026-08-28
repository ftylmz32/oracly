/// Personal Memory Core — compact, private, persistent.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/intelligence/domain/models/personal_memory_summary.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_builder.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_or_copy.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_privacy.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_service.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/services/memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/personal_discovery/pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 19);

  Future<PersonalMemoryService> _service() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    return PersonalMemoryService(PersonalMemoryStore(storage));
  }

  test('new user has empty memory', () async {
    final service = await _service();
    expect(service.load().isEmpty, isTrue);
    expect(service.observationalLine(), isNull);
  });

  test('one discovery stays observational, not recurring memory yet', () async {
    final service = await _service();
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Karar vermek bu dönemde yavaş.')],
      ),
      now: now,
    );
    final summary = await service.reconcile(profile, now: now);
    // Single observation may not reach recurring insight cap — still no raw text.
    expect(summary.toJson().toString().toLowerCase(), isNot(contains('karar vermek bu dönemde')));
    expect(PersonalMemoryPrivacy.isSafe(summary.toJson()), isTrue);
  });

  test('multiple discoveries and repeated theme persist compactly', () async {
    final service = await _service();
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Karar vermek zor.', at: now.subtract(const Duration(days: 2))),
          pdeTarot('r2', 'Bu karar alma süreci netleşiyor.', at: now),
        ],
        coffee: [pdeCoffee('c1', 'Karar verip ilerlemek gerekiyor.')],
      ),
      now: now,
    );
    final first = await service.reconcile(profile, preferredName: 'Fatih', now: now);
    expect(first.isEmpty, isFalse);
    expect(first.preferredName, 'Fatih');
    expect(first.themes, isNotEmpty);
    expect(first.themes.first.frequency, greaterThanOrEqualTo(2));
    expect(first.themes.first.sourceDiversity, greaterThanOrEqualTo(1));
    expect(first.recentDiscoveries.any((d) => d.startsWith('tarot:')), isTrue);

    final line = PersonalMemoryOrCopy.observe(first)!;
    expect(line.toLowerCase(), contains('yeniden'));
    expect(line.toLowerCase(), contains('keşfin'));
    expect(line.toLowerCase(), isNot(contains('sen karar veremeyen')));
    expect(line.toLowerCase(), isNot(contains('memory')));
    expect(line.toLowerCase(), isNot(contains('kayıt')));
    expect(line.toLowerCase(), isNot(contains('embedding')));

    final encoded = first.toJson().toString();
    expect(encoded, isNot(contains('messagesJson')));
    expect(encoded, isNot(contains('apiKey')));
  });

  test('old theme vs recent theme prefers recency in topics', () async {
    final old = now.subtract(const Duration(days: 120));
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('old1', 'Cesaretle bir adım at.', at: old),
          pdeTarot('old2', 'Cesaret teması yeniden.', at: old),
          pdeTarot('new1', 'Karar vermek önde.', at: now),
          pdeTarot('new2', 'Karar alma netleşiyor.', at: now),
        ],
        coffee: [pdeCoffee('c1', 'Karar verip ilerlemek.')],
      ),
      now: now,
    );
    final summary = PersonalMemoryBuilder.fromProfile(profile, now: now);
    expect(summary.themes, isNotEmpty);
    if (summary.recentTopics.isNotEmpty) {
      expect(summary.recentTopics.first, isNot(equals('courage')));
    }
  });

  test('restart keeps memory; clear empties it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    final service = PersonalMemoryService(PersonalMemoryStore(storage));

    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'İletişim kurmak önemli.', at: now),
          pdeTarot('r2', 'İletişim teması yeniden.', at: now),
        ],
        coffee: [pdeCoffee('c1', 'Konuşmak ve dinlemek.')],
      ),
      now: now,
    );
    await service.reconcile(profile, preferredName: 'Ada', now: now);
    expect(service.load().preferredName, 'Ada');

    // Simulate restart with same prefs backing store.
    final again = PersonalMemoryService(PersonalMemoryStore(LocalStorage(prefs)));
    expect(again.load().preferredName, 'Ada');
    expect(again.load().themes, isNotEmpty);

    await again.clear();
    expect(again.load().isEmpty, isTrue);
    expect(again.observationalLine(), isNull);
  });

  test('chat-only themes do not inflate personal memory', () async {
    final service = await _service();
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        conversations: [
          pdeOr(
            'chat1',
            'Karar vermeli miyim? Karar almak zor.',
            at: now,
          ),
        ],
      ),
      now: now,
    );
    final summary = await service.reconcile(profile, now: now);
    expect(
      summary.themes.any((t) => t.id == 'decision' || t.label.contains('karar')),
      isFalse,
    );
  });

  test('MemoryService.clearMemory clears personal memory key', () async {
    SharedPreferences.setMockInitialValues({
      PersonalMemoryStore.key: '{"schemaVersion":1,"preferredName":"X","themes":[],"recentDiscoveries":[],"preferences":[],"recentTopics":[],"fingerprint":"x"}',
      'user_memories': ['{"category":"general","content":"hi","importance":"normal","createdAt":"2026-08-01T00:00:00.000"}'],
    });
    await MemoryService().clearMemory();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PersonalMemoryStore.key), isNull);
    expect(prefs.getStringList('user_memories'), isNull);
  });

  test('no write when fingerprint unchanged', () async {
    final service = await _service();
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Değişim kapıda.', at: now),
          pdeTarot('r2', 'Bu değişim yumuşak.', at: now),
        ],
        coffee: [pdeCoffee('c1', 'Değişim görünüyor.')],
      ),
      now: now,
    );
    final a = await service.reconcile(profile, now: now);
    final b = await service.reconcile(profile, now: now.add(const Duration(minutes: 5)));
    expect(b.fingerprint, a.fingerprint);
    expect(b.updatedAt, a.updatedAt);
  });

  test('privacy rejects raw transcript payloads', () {
    expect(
      PersonalMemoryPrivacy.isSafe({
        'messagesJson': ['secret chat'],
        'themes': [],
      }),
      isFalse,
    );
    expect(
      PersonalMemoryPrivacy.isSafe(PersonalMemorySummary.empty.toJson()),
      isTrue,
    );
  });
}
