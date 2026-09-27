/// Dream Phase 1 — canonical storage/owner env + held AI for isolation tests.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_dream_repository.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';
import 'dream_honesty_fakes.dart';

const phase1NarrativeA =
    'Rüyamda eski evimin açık penceresinden sessiz bir deniz görünüyordu.';
const phase1NarrativeA2 =
    'Rüyamda bahçedeki eski saat durmuştu ve kapı yavaşça aralandı.';

/// Live-configured AI whose reply can be held until the test releases it.
class HeldDreamAi extends LiveDreamAiStub {
  HeldDreamAi({this.hold = false});

  bool hold;
  int calls = 0;
  final narratives = <String>[];
  final _entered = Completer<void>();
  Completer<void>? _gate;

  Future<void> get entered => _entered.future;

  void release() => _gate?.complete();

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async {
    calls++;
    narratives.add(context.narrative);
    if (hold) {
      final gate = _gate = Completer<void>();
      if (!_entered.isCompleted) _entered.complete();
      await gate.future;
    }
    return super.analyzeDream(context);
  }
}

class DreamPhase1Env {
  DreamPhase1Env._(this.storage, this.ai);

  static Future<DreamPhase1Env> open({
    String owner = 'owner-a',
    HeldDreamAi? ai,
  }) async {
    SharedPreferences.setMockInitialValues({
      UserLocalDataIsolation.ownerKey: owner,
    });
    await installTestPathProvider('oracly-dream-p1-');
    return DreamPhase1Env._(await LocalStorage.open(), ai ?? HeldDreamAi());
  }

  final LocalStorage storage;
  final HeldDreamAi ai;

  late final memory = OraclyMemoryStore(storage);
  late final repo = LocalDreamRepository(storage, memory: memory);
  late final versionStore = ReadingVersionStore(storage);
  late final versions = ReadingVersionService(versionStore);
  late final isolation = UserLocalDataIsolation(
    storage,
    secureStorage: InMemorySecureStorage(),
  );

  DreamExperienceService service() => DreamExperienceService(
        repository: repo,
        ai: ai,
        owner: DreamOwnerGuard.fromStorage(storage),
        versions: versions,
        memory: OraclyMemoryRetriever(memory),
      );

  /// Canonical switch: wipe → commit owner → bump epoch.
  Future<void> switchTo(String uid) async {
    final result = await isolation.onSignedIn(uid);
    expect(result.success, isTrue, reason: '$result');
  }

  int get recordCount => storage.getStringList('dream_records')?.length ?? 0;

  int get dreamMemoryCount =>
      memory.all().where((m) => m.source.type == OraclyReadingType.dream).length;

  String? get versionsRaw => storage.getString(ReadingVersionStore.key);

  /// Everything a stale/in-flight operation must never have touched.
  String persistedDreamState() => [
        storage.getStringList('dream_records')?.join('|') ?? '',
        storage.getStringList(OraclyMemoryStore.key)?.join('|') ?? '',
        versionsRaw ?? '',
      ].join('#');
}
