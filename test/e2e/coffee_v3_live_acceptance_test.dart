/// Slice 6 — Coffee V3 CONTROLLED REAL-PROVIDER acceptance (ONE attempt).
///
/// Same real client / real HTTP / real backend + worker as the Slice 5 E2E,
/// but the harness runs in `--live` mode: the REAL OpenAI transport behind
/// the fail-closed guard (official endpoint only; ≤2 attempts, ≤6 requests
/// per session; ≤1 observer + ≤2 writer per attempt; ambiguous → sealed).
///
/// Requires owner-provided REAL photos + rights.txt and a dedicated
/// non-production credential (checked by the harness preflight). Skipped
/// unless ORACLY_COFFEE_V3_LIVE_HANDSHAKE is set by
/// tool/e2e/run_coffee_v3_live_acceptance.sh. Never commit outputs.
///
/// No TestWidgetsFlutterBinding (it would block real loopback HTTP).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v3/controllers/coffee_v3_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_creation_gate.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_result_text.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../support/test_path_provider.dart';

final _handshakePath = Platform.environment['ORACLY_COFFEE_V3_LIVE_HANDSHAKE'];
final Object _skip = _handshakePath == null
    ? 'Set ORACLY_COFFEE_V3_LIVE_HANDSHAKE (run tool/e2e/run_coffee_v3_live_acceptance.sh)'
    : false;

/// The trusted intention for the live attempt (default: the "Genel" chip).
final _intention =
    Platform.environment['ORACLY_COFFEE_LIVE_INTENTION'] ?? 'Önümüzdeki dönem genel olarak';

class _NoProviderAi implements OraclyAiService {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('the client must never call a provider');
  }
}

void main() {
  test('ONE real-provider Coffee V3 reading: real photos → frozen pipeline → exact restore (or honest terminal)',
      () async {
    final hs = Map<String, dynamic>.from(
      jsonDecode(File(_handshakePath!).readAsStringSync()) as Map,
    );
    expect(hs['live'], isTrue, reason: 'harness must be in --live mode');
    final inputDir = hs['liveInputDir'] as String;

    final root = await Directory.systemTemp.createTemp('coffee_v3_live_');
    PathProviderPlatform.instance = TestPathProvider(root.path);
    OraclyL10n.bind('tr');
    FeatureFlagRuntime.refreshFromRemote({'coffee_v3_four_view': true}); // process-local only
    final storage = LocalStorage.ephemeral();
    final readings = CoffeeReadingStore(storage);
    final ai = _NoProviderAi();
    final calls = <String>[];
    final operationIds = <String>[];

    Future<ReadingOperationWire?> send(String method, String path, Map<String, Object>? body) async {
      final client = http.Client();
      try {
        final uri = Uri.parse('${hs['base']}$path');
        final headers = {
          'Authorization': 'Bearer ${hs['tokenA']}',
          'X-Firebase-AppCheck': hs['appCheck'] as String,
          'Content-Type': 'application/json',
        };
        final res = method == 'GET'
            ? await client.get(uri, headers: headers)
            : await client.post(uri, headers: headers, body: jsonEncode(body ?? const <String, Object>{}));
        calls.add('$method $path ${res.statusCode}');
        final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
        return ReadingOperationWire(
          statusCode: res.statusCode,
          json: decoded is Map ? Map<String, dynamic>.from(decoded) : null,
        );
      } catch (_) {
        return null;
      } finally {
        client.close();
      }
    }

    Future<Map<String, dynamic>> state(String operationId) async {
      final res = await http.get(Uri.parse('${hs['control']}/state?operationId=$operationId'));
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }

    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: send),
      acceleration: ReadingAccelerationClient(send: send),
      send: send,
    );
    final c = CoffeeV3FlowController(
      submission: CoffeeV3SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(send),
        store: CoffeeV3SubmissionStore(storage, ownerId: 'e2e-owner-a', requireOwner: true),
        normalizer: const DefaultCoffeeV3Normalizer(coffeeV2DefaultNormalizeMessages),
        creationAllowed: () => CoffeeV3CreationGate.creationAllowed,
      ),
      flow: flow,
      experience: CoffeeExperienceService(store: readings, analysis: OpenAiCoffeeAnalysis(ai: ai)),
    );

    try {
      // Real photos are COPIED to a temp "gallery" so originals are never touched.
      await c.boot();
      c.dismissIntro();
      for (final slot in coffeeV3CanonicalSlotOrder) {
        final copy = File('${root.path}/src_${slot.wireValue}.jpg');
        await File('$inputDir/${slot.wireValue}.jpg').copy(copy.path);
        c.setPreviewCandidate(slot, CoffeeImagePick(path: copy.path, mimeType: 'image/jpeg'));
        final outcome = await c.confirmCandidate();
        expect(outcome, CoffeeV3ConfirmOutcome.committedAdvance, reason: '${slot.wireValue}: ${c.lastSelectionFailure}');
      }
      await c.setCustomIntention(_intention);
      expect(c.canSubmit, isTrue);

      await c.beginSubmission();
      final opId = c.operationId;
      expect(opId, isNotNull, reason: 'create failed: ${c.createBlock}');
      operationIds.add(opId!);
      expect(calls.where((x) => x.startsWith('POST /v1/reading-operations ')), hasLength(1));
      expect(calls.where((x) => x.contains('/staged-image')), hasLength(4));

      final deadline = DateTime.now().add(const Duration(minutes: 6));
      while (c.reading == null && c.observeError == null) {
        if (DateTime.now().isAfter(deadline)) fail('no outcome within 6 minutes');
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      final st = await state(opId);
      final provider = Map<String, dynamic>.from(st['liveProvider'] as Map);
      final records = (provider['records'] as List).cast<Map>();
      final observers = records.where((r) => r['kind'] == 'observer').toList();
      final writers = records.where((r) => r['kind'] == 'writer').toList();
      expect(records.length, lessThanOrEqualTo(3)); // one attempt
      expect(observers, hasLength(1));
      expect(observers.single['imageCount'], 4); // four photos, one request
      expect(writers.length, lessThanOrEqualTo(2));
      expect(st['operationCount'], 1);

      // ignore: avoid_print
      print('LIVE_PROVIDER_RECORDS ${jsonEncode(records)}');
      if (c.reading != null) {
        final server = Map<String, dynamic>.from((st['result'] as Map)['data'] as Map);
        final reading = c.reading!;
        expect(server['coffeeResultContract'], 'm2_public_v1');
        expect((server['overall'] as String).trim(), isNotEmpty);
        expect(reading.isM2PublicV1, isTrue);
        expect(utf8.encode(CoffeeResultText.overall(reading)), utf8.encode(server['overall'] as String));
        expect(st['resultCount'], 1);
        expect((st['operation'] as Map)['status'], 'ready');
        expect(readings.byId(reading.id)?.overall, server['overall']);
        // ignore: avoid_print
        print('LIVE_OUTCOME success (prose written to the external evidence file for review)');
      } else {
        expect((st['operation'] as Map)['status'], 'failed');
        expect(['invalid', 'unavailable'], contains((st['operation'] as Map)['failureCode']));
        expect(st['result'], isNull);
        // ignore: avoid_print
        print('LIVE_OUTCOME terminal ${(st['operation'] as Map)['failureCode']}');
      }
      expect(ai.calls, 0);
      expect(c.stage, CoffeeV3FlowStage.activeObserving);
    } finally {
      c.dispose();
      FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
      // Seal the guard + write redacted evidence OUTSIDE the repository.
      await http.post(
        Uri.parse('${hs['control']}/shutdown'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'operationIds': operationIds}),
      );
      try {
        await root.delete(recursive: true);
      } catch (_) {}
    }
  }, skip: _skip, timeout: const Timeout(Duration(minutes: 8)));
}
