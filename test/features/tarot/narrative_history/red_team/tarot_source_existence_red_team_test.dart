/// Phase 4C red-team — source-existence firewall for stale ghosts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../personal_discovery/pde_test_fixtures.dart';
import '../tarot_4c_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase4cHarness h;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    h = Phase4cHarness(LocalStorage(await SharedPreferences.getInstance()));
    await setOwner(h.storage, null);
  });

  Future<Set<String>> memIds() async {
    final r = await h.loader().load(currentOwnerId: null);
    return r.snapshot.connectedMemories.map((e) => e.sourceId).toSet();
  }

  test('stale ghosts excluded then legitimate sources appear', () async {
    for (final entry in [
      ('t-stale', OraclyReadingType.tarot),
      ('c-stale', OraclyReadingType.coffee),
      ('p-stale', OraclyReadingType.palm),
      ('d-stale', OraclyReadingType.dream),
      ('sm-stale', OraclyReadingType.soulmate),
      ('bc-stale', OraclyReadingType.birthChart),
    ]) {
      await h.memory.upsert(readingMemory(sourceId: entry.$1, type: entry.$2));
    }
    expect(await memIds(), isEmpty);

    await h.tarot.saveSession(completedSession(id: 't-live'));
    await h.memory.upsert(
      readingMemory(sourceId: 't-live', type: OraclyReadingType.tarot),
    );
    await CoffeeReadingStore(h.storage).save(pdeCoffee('c-live', 'x'));
    await h.memory.upsert(
      readingMemory(sourceId: 'c-live', type: OraclyReadingType.coffee),
    );
    await PalmReadingStore(h.storage).save(pdePalm('p-live', 'x'));
    await h.memory.upsert(
      readingMemory(sourceId: 'p-live', type: OraclyReadingType.palm),
    );
    await h.dreams.save(pdeDream('d-live', 'x'));
    await h.memory.upsert(
      readingMemory(sourceId: 'd-live', type: OraclyReadingType.dream),
    );
    await writeSoulMateMeta(h.storage, id: 'sm-live', authoritative: true);
    await h.memory.upsert(
      readingMemory(sourceId: 'sm-live', type: OraclyReadingType.soulmate),
    );
    await saveJourneyChart(h.storage, 'bc-live');
    await h.memory.upsert(
      readingMemory(sourceId: 'bc-live', type: OraclyReadingType.birthChart),
    );

    expect(await memIds(), {
      't-live',
      'c-live',
      'p-live',
      'd-live',
      'sm-live',
      'bc-live',
    });
  });

  test('portrait-only soulmate excluded', () async {
    await writeSoulMateMeta(h.storage, id: 'sm-p', authoritative: false);
    await h.memory.upsert(
      readingMemory(sourceId: 'sm-p', type: OraclyReadingType.soulmate),
    );
    expect(await memIds(), isEmpty);
  });

  test('incomplete birth chart excluded', () async {
    final incomplete = const NatalChartCalculator().calculate(
      BirthProfile(
        birthDate: DateTime(1990, 3, 25),
        birthPlace: 'Ankara',
        birthTimeKnown: false,
      ),
    );
    await h.birthCharts.save(BirthChartRecordMapper.toRecord(incomplete));
    await h.memory.upsert(
      readingMemory(
        sourceId: incomplete.id,
        type: OraclyReadingType.birthChart,
      ),
    );
    expect(await memIds(), isEmpty);
  });
}
