/// Slice 5 — Coffee V3 four-view LOCAL TRANSPORT E2E.
///
/// Drives the REAL Flutter V3 client (real normalizer, real creation gate,
/// real submission / flow controllers, real ReadingLiveFlow / gateways,
/// real Slice 3 result restore) over REAL HTTP (package:http, the same
/// exchange as the production reading sender) against the REAL backend app
/// + REAL worker in `backend/tests/e2e/coffee-v3-e2e-harness.ts`.
///
/// The provider is a scripted FAKE inside the harness: every observer /
/// writer output is SYNTHETIC. A pass proves integration and frozen-gate
/// plumbing only — NOT real interpretation quality or provider acceptance.
///
/// Skipped unless ORACLY_COFFEE_V3_E2E_HANDSHAKE points at the harness
/// handshake file (see tool/e2e/run_coffee_v3_e2e.sh).
///
/// Deliberately NOT initializing TestWidgetsFlutterBinding: it would block
/// real loopback HTTP. Path provider is a deterministic local fake.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v3/controllers/coffee_v3_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_creation_gate.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_work_files.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_result_text.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/copy/reading_live_copy.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../support/coffee_v2_test_support.dart' show plainJpegBytes;
import '../support/test_path_provider.dart';

final _handshakePath = Platform.environment['ORACLY_COFFEE_V3_E2E_HANDSHAKE'];
final Object _skip = _handshakePath == null
    ? 'Set ORACLY_COFFEE_V3_E2E_HANDSHAKE (run tool/e2e/run_coffee_v3_e2e.sh)'
    : false;

/// The trusted decision intention the harness's synthetic writer fixture is
/// built for (a valid custom intention under trusted_intention_v1).
const _decision = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';

class _NoProviderAi implements OraclyAiService {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('client must never call a provider: ${invocation.memberName}');
  }
}

class _Call {
  _Call(this.method, this.path, this.body, this.status);
  final String method;
  final String path;
  final Map<String, Object>? body;
  final int? status;
}

/// Same HTTP exchange as the production reading sender (package:http,
/// JSON body, Bearer + X-Firebase-AppCheck), with test credentials and
/// explicit, test-only fault injection.
class _E2ESender {
  _E2ESender(this.base, this.token, this.appCheck);
  final String base;
  final String token;
  final String appCheck;
  final calls = <_Call>[];
  bool dropNextCreateResponse = false; // server DOES create; response lost
  String? dropStageSlotOnce; // request never sent (connection lost)
  bool dropNextResultResponse = false; // server returns it; response lost

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    if (method == 'POST' &&
        path.endsWith('/staged-image') &&
        body?['slot'] == dropStageSlotOnce) {
      dropStageSlotOnce = null;
      calls.add(_Call(method, path, body, null));
      return null;
    }
    final client = http.Client();
    try {
      final uri = Uri.parse('$base$path');
      final headers = {
        'Authorization': 'Bearer $token',
        'X-Firebase-AppCheck': appCheck,
        'Content-Type': 'application/json',
      };
      final response = method == 'GET'
          ? await client.get(uri, headers: headers)
          : await client.post(uri,
              headers: headers, body: jsonEncode(body ?? const <String, Object>{}));
      calls.add(_Call(method, path, body, response.statusCode));
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final isCreate = method == 'POST' && path == '/v1/reading-operations';
      if (isCreate && dropNextCreateResponse) {
        dropNextCreateResponse = false;
        return null;
      }
      if (method == 'GET' && path.endsWith('/result') && dropNextResultResponse) {
        dropNextResultResponse = false;
        return null;
      }
      return ReadingOperationWire(
        statusCode: response.statusCode,
        json: decoded is Map ? Map<String, dynamic>.from(decoded) : null,
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  List<_Call> get creates => calls
      .where((c) => c.method == 'POST' && c.path == '/v1/reading-operations')
      .toList();
  List<_Call> get stages =>
      calls.where((c) => c.path.endsWith('/staged-image')).toList();
  List<_Call> get resultFetches =>
      calls.where((c) => c.method == 'GET' && c.path.endsWith('/result')).toList();
  List<_Call> get featureWide =>
      calls.where((c) => c.path.startsWith('/v1/reading-flow/active')).toList();
}

late Map<String, dynamic> _hs;

Future<Map<String, dynamic>> _control(String method, String path,
    {Map<String, Object?>? body, Map<String, String>? query}) async {
  final uri = Uri.parse('${_hs['control']}$path').replace(queryParameters: query);
  final res = method == 'GET'
      ? await http.get(uri)
      : await http.post(uri,
          headers: {'content-type': 'application/json'}, body: jsonEncode(body ?? {}));
  return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
}

Future<Map<String, dynamic>> _state(String? operationId,
        {String stack = 'on', String owner = 'a'}) =>
    _control('GET', '/state', query: {
      'stack': stack,
      'owner': owner,
      'operationId': ?operationId,
    });

Future<void> _script(String observation, [List<String> writer = const []]) =>
    _control('POST', '/script', body: {'observation': observation, 'writer': writer});

Future<void> _waitFor(Future<bool> Function() condition,
    {int seconds = 20, String what = 'condition'}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out waiting for $what');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

String _sha(List<int> bytes) => crypto.sha256.convert(bytes).toString();

void main() {
  late Directory root;
  late Directory sources; // simulated camera/gallery originals (synthetic)
  late LocalStorage storage;
  late CoffeeReadingStore readings;
  late _NoProviderAi ai;
  final controllers = <CoffeeV3FlowController>[];
  var sourceCounter = 0;
  var imageSize = 20000;

  setUpAll(() {
    if (_handshakePath != null) {
      _hs = Map<String, dynamic>.from(
        jsonDecode(File(_handshakePath!).readAsStringSync()) as Map,
      );
    }
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('coffee_v3_e2e_');
    PathProviderPlatform.instance = TestPathProvider(root.path);
    sources = Directory('${root.path}/DCIM')..createSync(recursive: true);
    storage = LocalStorage.ephemeral();
    readings = CoffeeReadingStore(storage);
    ai = _NoProviderAi();
    OraclyL10n.bind('tr');
    // Test-only, process-local client rollout override (never remote).
    FeatureFlagRuntime.refreshFromRemote({'coffee_v3_four_view': true});
  });

  tearDown(() async {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
    try {
      await root.delete(recursive: true);
    } catch (_) {}
  });

  _E2ESender sender({bool flagOffServer = false, String owner = 'a'}) => _E2ESender(
        flagOffServer ? _hs['baseFlagOff'] as String : _hs['base'] as String,
        owner == 'a' ? _hs['tokenA'] as String : _hs['tokenB'] as String,
        _hs['appCheck'] as String,
      );

  CoffeeV3FlowController build(_E2ESender s, {String clientOwner = 'e2e-owner-a'}) {
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: s.send),
      acceleration: ReadingAccelerationClient(send: s.send),
      send: s.send,
    );
    final c = CoffeeV3FlowController(
      submission: CoffeeV3SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(s.send),
        store: CoffeeV3SubmissionStore(storage, ownerId: clientOwner, requireOwner: true),
        // REAL V3 normalizer (ImageNormalizer → {support}/coffee_v3_work).
        normalizer: const DefaultCoffeeV3Normalizer(coffeeV2DefaultNormalizeMessages),
        // REAL creation gate: rollout flag AND Turkish UI.
        creationAllowed: () => CoffeeV3CreationGate.creationAllowed,
        newSourceRequestId: () =>
            'coffee-v3-e2e-${DateTime.now().microsecondsSinceEpoch}-${sourceCounter++}',
      ),
      flow: flow,
      experience: CoffeeExperienceService(
        store: readings,
        analysis: OpenAiCoffeeAnalysis(ai: ai), // Slice 3 m2_public_v1 restore
      ),
    );
    controllers.add(c);
    return c;
  }

  /// A synthetic, rights-safe JPEG "original" (no real photo, no Exif).
  Future<String> original(String name, {int? size}) async {
    final f = File('${sources.path}/$name.jpg');
    await f.writeAsBytes(plainJpegBytes(totalSize: size ?? (imageSize += 131)));
    return f.path;
  }

  Future<void> captureFour(CoffeeV3FlowController c, {bool intention = true}) async {
    await c.boot();
    expect(c.stage, CoffeeV3FlowStage.intro);
    c.dismissIntro();
    for (final slot in coffeeV3CanonicalSlotOrder) {
      expect(c.currentStepSlot, slot);
      c.setPreviewCandidate(slot, CoffeeImagePick(path: await original('src_${slot.name}_$imageSize')));
      expect(await c.confirmCandidate(), CoffeeV3ConfirmOutcome.committedAdvance);
    }
    if (intention) await c.setCustomIntention(_decision);
  }

  List<String> workFiles() {
    final dir = Directory('${root.path}/${CoffeeV3WorkFiles.dirName}');
    return dir.existsSync()
        ? dir.listSync().whereType<File>().map((f) => f.path).toList()
        : <String>[];
  }

  group('success journey', () {
    test('1-16: capture → create (lost response, same id) → 4 stages → worker → m2_public_v1 → restore exact',
        () async {
      final s = sender();
      final c = build(s);
      await captureFour(c);

      // 3/4: four normalized, distinct, app-owned working copies.
      final assets = {for (final slot in coffeeV3CanonicalSlotOrder) slot: c.record.slots[slot]!.asset!};
      expect(assets.values.map((a) => a.sha256).toSet(), hasLength(4));
      for (final a in assets.values) {
        expect(await CoffeeV3WorkFiles.isOwned(a.path), isTrue);
        expect(_sha(await File(a.path).readAsBytes()), a.sha256);
      }
      expect(c.canSubmit, isTrue);

      await _script('ritag', ['good']);
      await _control('POST', '/hold', body: {'hold': true});

      // 6/7: the create response is LOST after the server created it.
      s.dropNextCreateResponse = true;
      await c.beginSubmission();
      expect(c.operationId, isNull);
      expect(c.createBlock, CoffeeV3CreateBlock.connectionLost);
      final durableSource = c.record.sourceRequestId;
      expect(durableSource, isNotNull);
      await c.beginSubmission(); // retry → createIfAbsent returns the SAME op
      final opId = c.operationId!;
      expect(s.creates, hasLength(2));
      expect(s.creates.map((x) => x.body!['sourceRequestId']).toSet(), {durableSource});
      expect(s.creates.first.body, {
        'readingType': 'coffee',
        'sourceRequestId': durableSource,
        'language': 'tr',
        'intention': _decision,
        'coffeeInputContract': 'trusted_intention_v1',
        'coffeeCaptureContract': 'four_view_v3',
      });

      // 8/9: four sequential canonical stages; server integrity.
      expect(s.stages.map((x) => x.body!['slot']), [
        'v3_cup_handle_far',
        'v3_cup_turn_a',
        'v3_cup_turn_b',
        'v3_saucer',
      ]);
      expect(s.stages.every((x) => x.path == '/v1/reading-operations/$opId/staged-image'), isTrue);
      var st = await _state(opId);
      expect(st['operationCount'], 1);
      expect((st['operation'] as Map)['coffeeCaptureContract'], 'four_view_v3');
      final slots = (st['v3Slots'] as List).cast<Map>();
      expect(slots.map((r) => r['slot']), ['v3_cup_handle_far', 'v3_cup_turn_a', 'v3_cup_turn_b', 'v3_saucer']);
      final hashes = Map<String, dynamic>.from(st['objectHashes'] as Map);
      for (final r in slots) {
        final slot = coffeeV3CanonicalSlotOrder.firstWhere((x) => x.wireValue == r['slot']);
        expect(r['ownerUserId'], _hs['ownerKeyA']);
        expect(r['contentType'], 'image/jpeg');
        expect(r['uploadState'], 'complete');
        expect(r['checksumSha256'], assets[slot]!.sha256); // client sha == server sha
        expect(hashes[r['objectPath']], assets[slot]!.sha256); // stored bytes intact
      }
      expect(st['resultCount'], 0);

      // 10-12: release the real worker (task due after the wait).
      await _control('POST', '/hold', body: {'hold': false});
      await _waitFor(() async => c.reading != null, what: 'restored reading');

      st = await _state(opId);
      expect((st['operation'] as Map)['status'], 'ready');
      expect(st['resultCount'], 1);
      expect(st['providerCalls'], containsAllInOrder(['coffee_v3_observation', 'writer']));
      expect(st['pushes'], [opId]);
      final serverResult = Map<String, dynamic>.from((st['result'] as Map)['data'] as Map);
      expect(serverResult['coffeeResultContract'], 'm2_public_v1');

      // 13/14: real result contract restore; displayed text byte-exact.
      final reading = c.reading!;
      expect(reading.isM2PublicV1, isTrue);
      expect(reading.overall, serverResult['overall']);
      expect(utf8.encode(CoffeeResultText.overall(reading)), utf8.encode(serverResult['overall'] as String));
      expect(reading.visualObservation, '');
      expect(reading.symbols, isEmpty);
      expect(s.featureWide, isEmpty); // exact-operation observation only

      // 15: saved reading/history + handoff metadata until acknowledgement.
      await _waitFor(() async => c.record.resultPendingAcknowledgement, what: 'handoff');
      expect(readings.byId(reading.id)?.overall, serverResult['overall']);
      expect(c.record.resultId, reading.id);
      // 16: working copies released; originals untouched.
      await _waitFor(() async => workFiles().isEmpty, what: 'temp cleanup');
      expect(sources.listSync().whereType<File>(), hasLength(4));
      expect(ai.calls, 0);

      c.resetToFreshDraft(); // New Cup → acknowledge
      await _waitFor(() async => c.reading == null, what: 'ack');
      final store = CoffeeV3SubmissionStore(storage, ownerId: 'e2e-owner-a');
      expect(store.load(), isNull);
      expect(store.loadAcknowledgedOperationId(), opId);
      expect(readings.byId(reading.id), isNotNull); // history kept

      // Owner isolation on the SAME completed operation (real routes).
      final b = sender(owner: 'b');
      expect((await b.send('GET', '/v1/reading-operations/$opId', null))!.statusCode, 404);
      expect((await b.send('GET', '/v1/reading-operations/$opId/result', null))!.statusCode, isNot(200));
      final stolen = await b.send('POST', '/v1/reading-operations/$opId/staged-image', {
        'mimeType': 'image/jpeg',
        'imageBase64': base64Encode(plainJpegBytes(totalSize: 12345)),
        'slot': 'v3_saucer',
      });
      expect(stolen!.statusCode, isNot(200));
      expect((await _state(opId))['resultCount'], 1);
    }, skip: _skip, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('negative scenarios', () {
    test('server V3 flag OFF refuses creation: draft kept, nothing staged or created', () async {
      final s = sender(flagOffServer: true);
      final c = build(s);
      await captureFour(c);
      final before = (await _state(null, stack: 'off'))['operationCount'];
      await c.beginSubmission();
      expect(c.createBlock, CoffeeV3CreateBlock.serverUnavailable);
      expect(c.operationId, isNull);
      expect(c.record.sourceRequestId, isNotNull);
      expect(s.creates.single.status, 400);
      expect(s.stages, isEmpty);
      expect((await _state(null, stack: 'off'))['operationCount'], before);
      expect(workFiles(), hasLength(4)); // photos preserved
    }, skip: _skip);

    test('client flag OFF: an empty V3 visit hands back to the default (V2) route', () async {
      FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
      final c = build(sender());
      await c.boot();
      expect(CoffeeV3CreationGate.creationAllowed, isFalse);
      expect(c.stage, CoffeeV3FlowStage.exitToDefault);
    }, skip: _skip);

    test('missing fourth photo / duplicate photo: no operation is created', () async {
      final s = sender();
      final c = build(s);
      await c.boot();
      c.dismissIntro();
      final dup = await original('same_bytes', size: 33333);
      c.setPreviewCandidate(CoffeeV3PhotoSlot.cupHandleFar, CoffeeImagePick(path: dup));
      expect(await c.confirmCandidate(), CoffeeV3ConfirmOutcome.committedAdvance);
      c.setPreviewCandidate(CoffeeV3PhotoSlot.cupTurnA,
          CoffeeImagePick(path: await original('same_bytes_copy', size: 33333)));
      expect(await c.confirmCandidate(), CoffeeV3ConfirmOutcome.duplicate);
      for (final slot in [CoffeeV3PhotoSlot.cupTurnA, CoffeeV3PhotoSlot.cupTurnB]) {
        c.setPreviewCandidate(slot, CoffeeImagePick(path: await original('ok_${slot.name}')));
        await c.confirmCandidate();
      }
      await c.setCustomIntention(_decision);
      expect(c.canSubmit, isFalse); // saucer missing
      await c.beginSubmission();
      expect(s.creates, isEmpty);
    }, skip: _skip);

    test('interrupted upload resumes the SAME operation; restart + client flag OFF still recovers', () async {
      final s = sender();
      final c = build(s);
      await captureFour(c);
      await _script('ritag', ['good']);
      await _control('POST', '/hold', body: {'hold': true});
      s.dropStageSlotOnce = 'v3_cup_turn_b';
      await c.beginSubmission();
      final opId = c.operationId!;
      expect(c.stagingRetryable, isTrue);
      expect(((await _state(opId))['v3Slots'] as List), hasLength(2));
      await c.retryStaging();
      expect(c.operationId, opId);
      expect(((await _state(opId))['v3Slots'] as List), hasLength(4));
      expect(s.stages.map((x) => x.body!['slot']), [
        'v3_cup_handle_far', 'v3_cup_turn_a', 'v3_cup_turn_b', // 3rd lost
        'v3_cup_turn_b', 'v3_saucer',
      ]);

      // App restart with the client rollout flag now OFF.
      c.dispose();
      controllers.remove(c);
      FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
      final restarted = build(s);
      await restarted.boot();
      expect(restarted.operationId, opId);
      expect(restarted.stage, CoffeeV3FlowStage.activeObserving);
      await _control('POST', '/hold', body: {'hold': false});
      await _waitFor(() async => restarted.reading != null, what: 'recovered reading');
      expect(s.creates, hasLength(1)); // never a second operation
      expect((await _state(opId))['resultCount'], 1);
    }, skip: _skip, timeout: const Timeout(Duration(minutes: 2)));

    test('result fetch interrupted after completion restores the same reading', () async {
      final s = sender();
      final c = build(s);
      await captureFour(c);
      await _script('ritag', ['good']);
      s.dropNextResultResponse = true;
      await c.beginSubmission();
      final opId = c.operationId!;
      await _waitFor(() async => c.reading != null, what: 'reading after lost fetch');
      expect(s.resultFetches.length, greaterThanOrEqualTo(2));
      final st = await _state(opId);
      expect(st['resultCount'], 1);
      expect(c.reading!.overall, ((st['result'] as Map)['data'] as Map)['overall']);
    }, skip: _skip, timeout: const Timeout(Duration(minutes: 2)));

    test('insufficient observation → typed terminal failure, no reading, no writer call', () async {
      final s = sender();
      final c = build(s);
      await captureFour(c);
      await _script('insufficient');
      final writerBefore = ((await _state(null))['providerCalls'] as List).where((x) => x == 'writer').length;
      await c.beginSubmission();
      final opId = c.operationId!;
      await _waitFor(() async => c.observeError != null, what: 'terminal failure');
      expect(c.observeError, ReadingLiveCopy.failed);
      expect(c.reading, isNull);
      final st = await _state(opId);
      expect(st['operation'], containsPair('status', 'failed'));
      expect(st['operation'], containsPair('failureCode', 'invalid'));
      expect(st['result'], isNull);
      expect(st['v3Slots'], isEmpty); // staged views cleaned after failure
      expect((st['providerCalls'] as List).where((x) => x == 'writer').length, writerBefore);
      expect(readings.all(), isEmpty);
      expect((await _state(null))['pendingScripts'], 0); // observer-only, consumed
    }, skip: _skip, timeout: const Timeout(Duration(minutes: 2)));

    test('two writer gate rejections on an ACCELERATED op → terminal, refund exactly once', () async {
      final s = sender();
      await _control('POST', '/credit', body: {'owner': 'a', 'amount': 40});
      final balanceStart = ((await s.send('GET', '/v1/gems/balance', null))!.json!['data'] as Map)['balance'] as int;
      final c = build(s);
      await captureFour(c);
      await _script('ritag', ['checker_fail', 'scenario_fail']);
      await c.beginSubmission();
      final opId = c.operationId!;
      // Keep the free wait open for the paid acceleration window.
      await _control('POST', '/advance', body: {'ms': -60000});
      try {
        await _waitFor(() async => c.canAccelerate, what: 'acceleration quote');
        expect(c.accelerationCost, 10); // server-owned cost
        await c.accelerateWaiting();
        await _waitFor(() async => c.observeError != null, what: 'terminal after accelerate');
      } finally {
        await _control('POST', '/advance', body: {'ms': 60000});
      }
      final st = await _state(opId);
      expect(st['operation'], containsPair('status', 'failed'));
      expect(st['operation'], containsPair('failureCode', 'unavailable'));
      expect(st['result'], isNull);
      final balanceEnd = ((await s.send('GET', '/v1/gems/balance', null))!.json!['data'] as Map)['balance'] as int;
      expect(balanceEnd, balanceStart); // debited 10, refunded 10, once
      expect(c.reading, isNull);
    }, skip: _skip, timeout: const Timeout(Duration(minutes: 2)));

    test('logout wipe removes owned normalized copies only (originals untouched)', () async {
      final c = build(sender());
      await captureFour(c, intention: false);
      expect(workFiles(), hasLength(4));
      final result = await UserLocalDataWipe.run(storage, secureStorage: InMemorySecureStorage());
      expect(result.failedOperations, isNot(contains('coffee_v3_work_images')));
      expect(workFiles(), isEmpty);
      expect(storage.getString(CoffeeV3SubmissionStore.key), isNull);
      expect(sources.listSync().whereType<File>(), hasLength(4));
    }, skip: _skip);

    test('Coffee V2 over the same transport is never routed to V3 (and settles via 4C)', () async {
      final s = sender();
      final flow = ReadingLiveFlow(
        operations: ReadingOperationGateway(send: s.send),
        acceleration: ReadingAccelerationClient(send: s.send),
        send: s.send,
      );
      final v2 = CoffeeV2SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(s.send),
        store: CoffeeV2SubmissionStore(storage, ownerId: 'e2e-owner-a', requireOwner: true),
        normalizer: const DefaultCoffeeV2Normalizer(coffeeV2DefaultNormalizeMessages),
      );
      for (final slot in coffeeV2CanonicalSlotOrder) {
        await v2.setSlot(slot, CoffeeImagePick(path: await original('v2_${slot.name}')));
        await v2.confirmSlot(slot);
      }
      await v2.setIntention('Önümüzdeki dönem genel olarak');
      await _script('v2_no_meaning');
      final v3CallsBefore = ((await _state(null))['providerCalls'] as List)
          .where((x) => x == 'coffee_v3_observation').length;
      await v2.beginSubmission('coffee-v2-e2e-${DateTime.now().microsecondsSinceEpoch}');
      final opId = v2.record.operationId!;
      expect(s.creates.single.body!.containsKey('coffeeCaptureContract'), isFalse);
      expect(s.stages.map((x) => x.body!['slot']), ['cup_primary', 'cup_secondary', 'saucer']);
      await _waitFor(() async {
        final op = (await _state(opId))['operation'] as Map?;
        return op?['status'] == 'failed';
      }, what: 'V2 terminal');
      final st = await _state(opId);
      expect(st['operation'], containsPair('failureCode', 'invalid'));
      expect(st['result'], isNull);
      final calls = (st['providerCalls'] as List).cast<String>();
      expect(calls.last, 'coffee_v2_observation');
      expect(calls.where((x) => x == 'coffee_v3_observation').length, v3CallsBefore);
    }, skip: _skip, timeout: const Timeout(Duration(minutes: 2)));
  });
}
