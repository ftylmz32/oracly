/// Fortune rows survive a process restart as a disk preference file.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:oracly_new/core/auth/owner_history_scope.dart';
import 'package:oracly_new/core/auth/sign_out_local_cleanup.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_astrology_repository.dart';
import 'package:oracly_new/core/data/repositories/local_dream_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_integrity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late int epoch;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('oracly-history-restart-');
    PathProviderPlatform.instance = _TempPathProvider(dir.path);
    epoch = UserLocalDataIsolation.accountSwitchEpoch.value;
  });

  tearDown(() async {
    UserLocalDataIsolation.accountSwitchEpoch.value = epoch;
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('a closed app reopens the same account history from disk', () async {
    final first = LocalStorage.ephemeral();
    await first.setString(UserLocalDataIsolation.ownerKey, 'account-a');
    await _seed(first);
    final file = await _freeze(first, dir);
    final reopened = _thaw(file);

    expect(CoffeeReadingStore(reopened).byId('cup-a')?.overall, 'Cup A');
    expect(PalmReadingStore(reopened).byId('palm-a')?.overall, 'Palm A');
    final tarot = await MockHistoryRepository(reopened).getReadings();
    expect(tarot.single.aiSummary, 'Tarot A');
    final dreams = await LocalDreamRepository(reopened).getAll();
    expect(dreams.single.analysis, 'Dream A');
    final stars = await LocalYildiznameArtifactRepository(
      reopened,
      ownerId: 'account-a',
    ).getAll();
    expect(stars.single.ownerId, 'account-a');
    final soul = await SoulMateResultStore.readMeta(reopened);
    expect(soul?.name, 'Ada');
    expect(
      await LocalAstrologyRepository(reopened).getHistory(),
      isEmpty,
    );
  });

  test('sign-out clears local history and the same login does not restore it',
      () async {
    final first = LocalStorage.ephemeral();
    await first.setString(UserLocalDataIsolation.ownerKey, 'account-a');
    await _seed(first);
    final secure = InMemorySecureStorage();
    final wiped = await SignOutLocalCleanup.wipeDiskOnly(
      storage: first,
      secureStorage: secure,
    );
    expect(wiped.isComplete, isTrue, reason: '${wiped.failedOperations}');
    final file = await _freeze(first, dir);
    final reopened = _thaw(file);
    final isolation = UserLocalDataIsolation(reopened, secureStorage: secure);
    final signedIn = await isolation.onSignedIn('account-a');
    expect(signedIn.success, isTrue);
    expect(CoffeeReadingStore(reopened).all(), isEmpty);
    expect(await MockHistoryRepository(reopened).getReadings(), isEmpty);
    expect(await LocalDreamRepository(reopened).getAll(), isEmpty);
  });

  test('account B does not receive A, and a late row still cannot cross',
      () async {
    final first = LocalStorage.ephemeral();
    await first.setString(UserLocalDataIsolation.ownerKey, 'account-a');
    await _seed(first);
    final secure = InMemorySecureStorage();
    await SignOutLocalCleanup.wipeDiskOnly(
      storage: first,
      secureStorage: secure,
    );
    final reopened = _thaw(await _freeze(first, dir));
    final isolation = UserLocalDataIsolation(reopened, secureStorage: secure);
    await isolation.onSignedIn('account-b');
    expect(CoffeeReadingStore(reopened).all(), isEmpty);

    final stamp = (
      ownerId: 'account-a',
      epoch: epoch,
    );
    await expectLater(
      OwnerHistoryScope.commitBound(
        ownerId: stamp.ownerId,
        epoch: stamp.epoch,
        save: () => CoffeeReadingStore(reopened).save(_coffee()),
      ),
      throwsA(isA<OwnerHistoryRejected>()),
    );
    expect(CoffeeReadingStore(reopened).all(), isEmpty);
  });

  test('a corrupt local row is skipped and does not invent a result', () async {
    final first = LocalStorage.ephemeral();
    await CoffeeReadingStore(first).save(_coffee());
    final raw = first.getStringList(CoffeeReadingStore.key)!;
    await first.setStringList(CoffeeReadingStore.key, ['{bad', ...raw]);
    final reopened = _thaw(await _freeze(first, dir));
    final rows = CoffeeReadingStore(reopened).all();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'cup-a');
    expect(reopened.getString('gem_wallet_balance'), isNull);
  });
}

Future<void> _seed(LocalStorage storage) async {
  await CoffeeReadingStore(storage).save(_coffee());
  await PalmReadingStore(storage).save(
    PalmReading(
      id: 'palm-a',
      createdAt: DateTime.utc(2026, 10, 19),
      hand: PalmHand.right,
      overall: 'Palm A',
    ),
  );
  await MockHistoryRepository(storage).saveReading(
    ReadingModel(
      id: 'tarot-a',
      cardId: 17,
      cardName: 'The Star',
      cardImageAsset: 'star',
      spreadType: 'single',
      aiSummary: 'Tarot A',
      createdAt: DateTime.utc(2026, 10, 19),
      userId: 'account-a',
    ),
  );
  await LocalDreamRepository(storage).save(
    DreamRecord(
      id: 'dream-a',
      text: 'A path',
      analysis: 'Dream A',
      createdAt: DateTime.utc(2026, 10, 19),
    ),
  );
  final draft = YildiznameArtifact(
    id: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    ownerId: 'account-a',
    createdAtUtc: DateTime.utc(2026, 10, 19),
    source: YildiznameArtifactSource.legacyLocal,
    contentHash: 'pending',
    semanticDedupeKey: 'dedupe-a',
    payload: const {'kept': true},
  );
  await LocalYildiznameArtifactRepository(
    storage,
    ownerId: 'account-a',
  ).saveNew(
    YildiznameArtifact(
      id: draft.id,
      ownerId: draft.ownerId,
      createdAtUtc: draft.createdAtUtc,
      source: draft.source,
      contentHash: YildiznameArtifactIntegrity.compute(draft),
      semanticDedupeKey: draft.semanticDedupeKey,
      payload: draft.payload,
    ),
  );
  await storage.setString(
    SoulMateResultStore.metaKey,
    jsonEncode(
      SoulMateSavedResult(
        id: 'soul-a',
        createdAt: DateTime.utc(2026, 10, 19),
        name: 'Ada',
        birthDate: DateTime.utc(1990, 1, 1),
        portraitPath: '',
        parts: const SoulMateReadingParts(
          energy: 'E',
          attraction: 'A',
          dynamics: 'D',
          feeling: 'F',
          yourSide: 'Y',
          authoritative: true,
        ),
      ).toJson(),
    ),
  );
}

CoffeeReading _coffee() => CoffeeReading(
      id: 'cup-a',
      createdAt: DateTime.utc(2026, 10, 19),
      overall: 'Cup A',
      love: 'A',
      career: 'A',
      money: 'A',
      nearFuture: 'A',
      takeaway: 'A',
    );

Future<File> _freeze(LocalStorage storage, Directory dir) async {
  final out = <String, Object>{};
  for (final key in storage.keys) {
    final value = storage.peek(key);
    if (value != null) out[key] = value;
  }
  final file = File('${dir.path}/prefs.json');
  await file.writeAsString(jsonEncode(out));
  return file;
}

class _TempPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _TempPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}

LocalStorage _thaw(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) return LocalStorage.ephemeral();
  final seed = <String, Object>{};
  for (final entry in decoded.entries) {
    final key = entry.key.toString();
    final value = entry.value;
    if (value is String || value is int || value is double || value is bool) {
      seed[key] = value;
    } else if (value is List) {
      seed[key] = value.map((item) => item.toString()).toList();
    }
  }
  return LocalStorage.ephemeral(seed);
}
