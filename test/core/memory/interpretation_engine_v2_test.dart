import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';

OraclyMemory memory({
  required String id,
  required OraclyReadingType type,
  required DateTime at,
  required String summary,
  List<String> themes = const [],
  List<String> evidence = const [],
}) => OraclyMemory(
  id: 'reading:${type.name}:$id',
  kind: OraclyMemoryKind.reading,
  source: OraclyMemorySource(id: id, type: type, occurredAt: at, resultRef: id),
  summary: summary,
  themes: themes,
  evidence: evidence,
);

void main() {
  late LocalStorage storage;
  late OraclyMemoryStore store;
  late OraclyMemoryRetriever retriever;
  final now = DateTime(2026, 9, 9);

  setUp(() {
    storage = LocalStorage.ephemeral();
    store = OraclyMemoryStore(storage);
    retriever = OraclyMemoryRetriever(store);
  });

  test('no memory produces no historical claim', () {
    final packet = retriever.retrieve(query: 'Bugün ne görüyorsun?', now: now);
    expect(packet.items, isEmpty);
    expect(packet.toPrompt(), isEmpty);
  });

  test('one relevant previous reading is source attributed', () async {
    await store.upsert(
      memory(
        id: 't1',
        type: OraclyReadingType.tarot,
        at: now.subtract(const Duration(days: 2)),
        summary: 'İş konusunda iki seçenek arasında karar verme süreci.',
        themes: ['kariyer', 'karar'],
        evidence: ['Aşıklar'],
      ),
    );
    final packet = retriever.retrieve(
      query: 'Kariyer kararım ne olacak?',
      now: now,
    );
    expect(packet.items.single.memory.source.id, 't1');
    expect(packet.toPrompt(), contains('[tarot | 2026-09-07 | t1]'));
  });

  test('irrelevant old reading is not injected', () async {
    await store.upsert(
      memory(
        id: 'old',
        type: OraclyReadingType.dream,
        at: DateTime(2020),
        summary: 'Deniz kıyısında huzur.',
        themes: ['huzur'],
      ),
    );
    expect(
      retriever.retrieve(query: 'Kariyer kararım', now: now).items,
      isEmpty,
    );
    expect(
      retriever.forInterpretation(
        query: 'Kariyer kararım',
        currentType: OraclyReadingType.coffee,
      ),
      isNull,
    );
  });

  test(
    'reading injection is relevant, cross-feature, sourced and bounded',
    () async {
      await store.upsert(
        memory(
          id: 'tarot-source',
          type: OraclyReadingType.tarot,
          at: now,
          summary: 'Kariyer konusunda iki seçenek arasında karar.',
          themes: ['kariyer', 'karar'],
        ),
      );
      await store.upsert(
        memory(
          id: 'coffee-self',
          type: OraclyReadingType.coffee,
          at: now,
          summary: 'Kariyer kararı.',
          themes: ['kariyer'],
        ),
      );
      final prompt = retriever.forInterpretation(
        query: 'kariyer karar',
        currentType: OraclyReadingType.coffee,
      );
      expect(prompt, contains('tarot-source'));
      expect(prompt, isNot(contains('coffee-self')));
      expect(prompt!.length, lessThanOrEqualTo(220));
    },
  );

  test('empty current context never exports history', () async {
    await store.upsert(
      memory(
        id: 't1',
        type: OraclyReadingType.tarot,
        at: now,
        summary: 'Kariyer kararı.',
        themes: ['kariyer'],
      ),
    );
    expect(
      retriever.forInterpretation(
        query: '',
        currentType: OraclyReadingType.palm,
      ),
      isNull,
    );
  });

  test(
    'cross-feature recurring theme is synthesized only from two types',
    () async {
      await store.upsert(
        memory(
          id: 't1',
          type: OraclyReadingType.tarot,
          at: now,
          summary: 'İş için iki seçenek.',
          themes: ['karar'],
        ),
      );
      await store.upsert(
        memory(
          id: 'c1',
          type: OraclyReadingType.coffee,
          at: now,
          summary: 'Fincanda ikiye ayrılan yol.',
          themes: ['karar'],
          evidence: ['çatal yol'],
        ),
      );
      final packet = retriever.retrieve(
        query: 'Karar teması tekrar ediyor mu?',
        now: now,
      );
      expect(
        packet.items.map((e) => e.memory.source.type).toSet(),
        containsAll([OraclyReadingType.tarot, OraclyReadingType.coffee]),
      );
      expect(packet.recurringThemes, ['karar']);
    },
  );

  test('contradictory history forces uncertainty instruction', () async {
    await store.upsert(
      memory(
        id: 'a',
        type: OraclyReadingType.tarot,
        at: now,
        summary: 'İlişkide yakınlaşma.',
        themes: ['ilişki'],
      ),
    );
    await store.upsert(
      memory(
        id: 'b',
        type: OraclyReadingType.coffee,
        at: now,
        summary: 'İlişkide mesafe.',
        themes: ['ilişki'],
      ),
    );
    final prompt = retriever
        .retrieve(query: 'İlişkim nasıl?', now: now)
        .toPrompt();
    expect(prompt, contains('çelişki varsa kesin bağlantı kurma'));
  });

  test('duplicate persistence upserts by canonical id', () async {
    final first = memory(
      id: 'same',
      type: OraclyReadingType.tarot,
      at: now,
      summary: 'İlk yorum',
      themes: ['karar'],
    );
    await store.upsert(first);
    await store.upsert(
      memory(
        id: 'same',
        type: OraclyReadingType.tarot,
        at: now,
        summary: 'Güncel yorum',
        themes: ['karar'],
      ),
    );
    expect(store.all(), hasLength(1));
    expect(store.all().single.summary, 'Güncel yorum');
  });

  test('source deletion removes it from retrieval', () async {
    await store.upsert(
      memory(
        id: 'gone',
        type: OraclyReadingType.tarot,
        at: now,
        summary: 'Kariyer kararı',
        themes: ['kariyer'],
      ),
    );
    await store.removeBySource('gone');
    expect(retriever.retrieve(query: 'kariyer', now: now).items, isEmpty);
  });

  test('current Coffee visual evidence is placed before memory', () async {
    await store.upsert(
      memory(
        id: 't1',
        type: OraclyReadingType.tarot,
        at: now,
        summary: 'Karar zamanı.',
        themes: ['karar'],
      ),
    );
    final prompt = retriever
        .retrieve(
          query: 'karar',
          currentEvidence: ['fincanda ikiye ayrılan yol'],
          now: now,
        )
        .toPrompt();
    expect(
      prompt.indexOf('birincil kanıt'),
      lessThan(prompt.indexOf('[tarot')),
    );
  });

  test(
    'feature A can retrieve memory persisted by feature B after restart',
    () async {
      final coffee = CoffeeReading(
        id: 'cup1',
        createdAt: now,
        overall: 'İş konusunda iki yol arasında karar öne çıkıyor.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'Önceliklerini yaz.',
        visualObservation: 'Fincanın ortasında ikiye ayrılan koyu yol.',
      );
      await CoffeeReadingStore(storage, memory: store).save(coffee);
      final restarted = OraclyMemoryRetriever(OraclyMemoryStore(storage));
      final packet = restarted.retrieve(
        query: 'Tarot ile kahve falındaki karar benziyor mu?',
        now: now,
      );
      expect(packet.items.single.memory.source.type, OraclyReadingType.coffee);
      expect(packet.items.single.memory.evidence, isNotEmpty);
    },
  );

  test('packet is bounded and avoids generic mystical filler', () async {
    for (var i = 0; i < 20; i++) {
      await store.upsert(
        memory(
          id: '$i',
          type: OraclyReadingType.tarot,
          at: now.subtract(Duration(days: i)),
          summary: 'Kariyer kararı $i',
          themes: ['kariyer', 'karar'],
        ),
      );
    }
    final packet = retriever.retrieve(query: 'kariyer kararı', now: now);
    expect(packet.items.length, lessThanOrEqualTo(4));
    final prompt = packet.toPrompt();
    expect(prompt.length, lessThanOrEqualTo(1200));
    expect(prompt.toLowerCase(), isNot(contains('evren sana söylüyor')));
  });
}
