/// BATCH 5F — a real in-memory simulation of the reading-operation HTTP
/// surface (create / claim / complete / fail / active), for tests that
/// need `ReadingFeatureRunner`/`ReadingLiveFlow` to behave like the real
/// backend without a live server. This is NOT a shortcut around the
/// runner — the same `ReadingFeatureRunner.submit`/`ReadingLiveFlow` code
/// under test still runs; only the HTTP transport is faked.
library;

import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_feature_runner.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_input_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

class _FakeOp {
  _FakeOp({required this.id, required this.readingType, this.executionMode});
  final String id;
  final String readingType;
  String status = 'waiting';
  String? resultId;
  bool claimedOnce = false;
  /// SMD1 — set once at creation, exactly like the real
  /// `createIfAbsent`/`executionMode` contract: never overwritten by a
  /// later `create` call that reuses the same `sourceRequestId`.
  final String? executionMode;
}

/// Owner-less (single simulated user) in-memory reading-operation backend.
/// `immediatelyEligible: true` (default) means a freshly-created operation
/// can be claimed right away — tests don't need to fake wait durations.
class FakeReadingOperationBackend {
  FakeReadingOperationBackend({this.immediatelyEligible = true});

  /// Mutable so a test can flip false -> true mid-run to simulate a
  /// commercial wait timer elapsing without a real wait. Also drives the
  /// reported `waitFinished`/`remainingMs` below — before this, they were
  /// hardcoded `true`/`0` regardless of this flag, which is why no test
  /// ever caught `ReadingFeatureRunner` ignoring a snapshot's own
  /// `waitFinished` on `waiting` (every fake snapshot always claimed the
  /// wait was already over).
  bool immediatelyEligible;
  final Map<String, _FakeOp> _byId = {};
  final Map<String, _FakeOp> _bySource = {};
  // Mirrors the server's `readingOperationActive` doc: written once when an
  // operation is first created (while still `waiting`), then never cleared
  // — a later status change (ready/failed) is still found via this pointer,
  // exactly like `ReadingFlow.active()` on the real backend.
  final Map<String, String> _activeIdByType = {};
  final Map<String, Map<String, String>> _inputById = {};
  final Map<String, Map<String, dynamic>> _resultById = {};
  final Map<String, Map<String, String>> _portraitById = {};
  int _counter = 0;
  int accelerationCalls = 0;
  int accelerationDebitCount = 0;
  int resultFetchCalls = 0;
  int authoritativeBalance = 50;
  bool accelerationInsufficient = false;
  bool accelerationGenericConflict = false;
  int coffeeAccelerationCost = 10;
  int palmAccelerationCost = 15;
  final Set<String> _acceleratedIds = {};

  int _costFor(String readingType) =>
      readingType == 'coffee' ? coffeeAccelerationCost : palmAccelerationCost;

  /// Deterministic stand-in for the real backend's sha256-derived
  /// priceToken -- only needs to change whenever cost changes, and to be
  /// reproducible from (readingType, cost) alone, matching what the real
  /// server does. Not a security mechanism here either; the check below is
  /// pure comparison, exactly like the real ledger.
  String _tokenFor(String readingType, int cost) => 'tok-$readingType-$cost';

  /// Total distinct operations ever created — lets a test assert that a
  /// resume/recover call reused the existing operation rather than
  /// creating a duplicate.
  int get operationCount => _byId.length;

  static final _claimPath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/claim$',
  );
  static final _completePath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/complete$',
  );
  static final _failPath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/fail$',
  );
  static final _inputPath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/input$',
  );
  static final _acceleratePath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/accelerate$',
  );
  static final _stagePath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/staged-image$',
  );
  static final _resultPath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/result$',
  );
  static final _soulmatePortraitPath = RegExp(
    r'^/v1/reading-operations/([a-f0-9]{32})/soulmate-portrait$',
  );

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    if (method == 'POST' && path == '/v1/reading-operations') {
      return _create(body);
    }
    final stage = _stagePath.firstMatch(path);
    if (method == 'POST' && stage != null && _byId[stage.group(1)!] != null) {
      return ReadingOperationWire(
        statusCode: 200,
        json: {
          'data': {'operationId': stage.group(1), 'staged': true},
        },
      );
    }
    final result = _resultPath.firstMatch(path);
    if (method == 'GET' && result != null) {
      resultFetchCalls++;
      final data = _resultById[result.group(1)!];
      return data == null
          ? const ReadingOperationWire(statusCode: 404, json: null)
          : ReadingOperationWire(statusCode: 200, json: {'data': data});
    }
    final portrait = _soulmatePortraitPath.firstMatch(path);
    if (method == 'GET' && portrait != null) {
      final data = _portraitById[portrait.group(1)!];
      return data == null
          ? const ReadingOperationWire(statusCode: 404, json: null)
          : ReadingOperationWire(statusCode: 200, json: {'data': data});
    }
    final claim = _claimPath.firstMatch(path);
    if (method == 'POST' && claim != null) {
      return _claim(claim.group(1)!);
    }
    final accelerate = _acceleratePath.firstMatch(path);
    if (method == 'GET' && accelerate != null) {
      final op = _byId[accelerate.group(1)!];
      if (op == null) {
        return const ReadingOperationWire(statusCode: 404, json: null);
      }
      final cost = _costFor(op.readingType);
      return ReadingOperationWire(
        statusCode: 200,
        json: {
          'data': {
            'canonicalCost': cost,
            'balance': authoritativeBalance,
            'priceToken': _tokenFor(op.readingType, cost),
            // The free wait is "over" in this fake once immediatelyEligible
            // flips true -- same semantics as the real readyAt boundary.
            'payable': !immediatelyEligible,
          },
        },
      );
    }
    if (method == 'POST' && accelerate != null) {
      accelerationCalls++;
      final op = _byId[accelerate.group(1)!];
      if (op == null) {
        return const ReadingOperationWire(statusCode: 404, json: null);
      }
      if (accelerationGenericConflict) {
        return const ReadingOperationWire(
          statusCode: 409,
          json: {
            'error': {'code': 'conflict'},
          },
        );
      }
      if (accelerationInsufficient) {
        return const ReadingOperationWire(
          statusCode: 409,
          json: {
            'error': {'code': 'insufficient_gems'},
          },
        );
      }
      final cost = _costFor(op.readingType);
      final currentToken = _tokenFor(op.readingType, cost);
      if (_acceleratedIds.contains(op.id)) {
        return ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {
              'outcome': 'already_accelerated',
              'balance': authoritativeBalance,
              'canonicalCost': cost,
              'priceToken': currentToken,
              'idempotent': true,
            },
          },
        );
      }
      if (immediatelyEligible && op.status == 'waiting') {
        // The free wait is already over -- nothing left to sell, zero debit,
        // same as the real ledger's readyAt boundary check.
        return ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {
              'outcome': 'already_eligible',
              'balance': authoritativeBalance,
              'canonicalCost': cost,
              'priceToken': currentToken,
              'idempotent': false,
            },
          },
        );
      }
      final expectedToken = body?['expectedPriceToken'] as String?;
      if (expectedToken != null && expectedToken != currentToken) {
        // Same as the real ledger: a stale price never debits, it just
        // hands back the fresh cost/token for the UI to refresh.
        return ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {
              'outcome': 'price_changed',
              'balance': authoritativeBalance,
              'canonicalCost': cost,
              'priceToken': currentToken,
              'idempotent': false,
            },
          },
        );
      }
      authoritativeBalance -= cost;
      accelerationDebitCount++;
      _acceleratedIds.add(op.id);
      immediatelyEligible = true;
      op.status = 'processing';
      return ReadingOperationWire(
        statusCode: 200,
        json: {
          'data': {
            'outcome': 'accelerated',
            'balance': authoritativeBalance,
            'canonicalCost': cost,
            'priceToken': currentToken,
            'idempotent': false,
          },
        },
      );
    }
    if (method == 'GET' && path == '/v1/gems/balance') {
      return ReadingOperationWire(
        statusCode: 200,
        json: {
          'data': {'balance': authoritativeBalance},
        },
      );
    }
    final complete = _completePath.firstMatch(path);
    if (method == 'POST' && complete != null) {
      return _complete(complete.group(1)!, body);
    }
    final fail = _failPath.firstMatch(path);
    if (method == 'POST' && fail != null) {
      return _fail(fail.group(1)!);
    }
    if (method == 'GET' && path.startsWith('/v1/reading-flow/active')) {
      return _active(path);
    }
    final input = _inputPath.firstMatch(path);
    if (input != null && method == 'POST') {
      return _saveInput(input.group(1)!, body);
    }
    if (input != null && method == 'GET') {
      return _getInput(input.group(1)!);
    }
    return null;
  }

  void completeServerSide(
    String operationId, {
    required String resultId,
    Map<String, dynamic> result = const {'overall': 'server result'},
  }) {
    final op = _byId[operationId]!;
    op.status = 'ready';
    op.resultId = resultId;
    _resultById[operationId] = {
      'operationId': operationId,
      'resultId': resultId,
      'readingType': op.readingType,
      'persistedAt': DateTime.now().toUtc().toIso8601String(),
      'result': result,
    };
  }

  /// SMD1 — seeds the durable Soulmate portrait the fake worker would have
  /// persisted. Call alongside [completeServerSide] to simulate a `ready`
  /// durable operation end-to-end.
  void setSoulmatePortrait(
    String operationId, {
    required String imageBase64,
    String mimeType = 'image/png',
  }) {
    _portraitById[operationId] = {
      'operationId': operationId,
      'mimeType': mimeType,
      'imageBase64': imageBase64,
    };
  }

  ReadingOperationWire? _saveInput(String id, Map<String, Object>? body) {
    if (_byId[id] == null)
      return const ReadingOperationWire(statusCode: 404, json: null);
    _inputById[id] = {
      for (final entry in (body ?? const {}).entries)
        entry.key: '${entry.value}',
    };
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {'saved': true},
      },
    );
  }

  ReadingOperationWire? _getInput(String id) {
    if (_byId[id] == null)
      return const ReadingOperationWire(statusCode: 404, json: null);
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {'fields': _inputById[id]},
      },
    );
  }

  ReadingOperationWire _create(Map<String, Object>? body) {
    final readingType = body?['readingType'] as String?;
    final sourceRequestId = body?['sourceRequestId'] as String?;
    final key = '$readingType $sourceRequestId';
    final existing = _bySource[key];
    if (existing != null) {
      return ReadingOperationWire(
        statusCode: 200,
        json: {'data': _publicJson(existing)},
      );
    }
    final op = _FakeOp(
      id: _newId(),
      readingType: readingType ?? 'coffee',
      executionMode: body?['executionMode'] as String?,
    );
    _byId[op.id] = op;
    _bySource[key] = op;
    _activeIdByType[op.readingType] = op.id;
    return ReadingOperationWire(
      statusCode: 200,
      json: {'data': _publicJson(op)},
    );
  }

  ReadingOperationWire? _claim(String id) {
    final op = _byId[id];
    if (op == null) return null;
    var execute = false;
    if (op.status == 'waiting' && immediatelyEligible) {
      op.status = 'processing';
      execute = true;
    } else if (op.status == 'processing' &&
        op.resultId == null &&
        !op.claimedOnce) {
      execute = true;
    }
    if (execute) op.claimedOnce = true;
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {'execute': execute, 'operation': _publicJson(op)},
      },
    );
  }

  ReadingOperationWire? _complete(String id, Map<String, Object>? body) {
    final op = _byId[id];
    if (op == null) return null;
    op.status = 'ready';
    op.resultId = body?['resultId'] as String?;
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {'operation': _publicJson(op)},
      },
    );
  }

  ReadingOperationWire? _fail(String id) {
    final op = _byId[id];
    if (op == null) return null;
    op.status = 'failed';
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {'operation': _publicJson(op), 'refunded': false},
      },
    );
  }

  ReadingOperationWire _active(String path) {
    final uri = Uri.parse('http://fake$path');
    final type = uri.queryParameters['readingType'];
    final activeId = _activeIdByType[type];
    final found = activeId == null ? null : _byId[activeId];
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {'operation': found == null ? null : _publicJson(found)},
      },
    );
  }

  String _newId() {
    _counter++;
    return _counter.toRadixString(16).padLeft(32, '0');
  }

  /// Raw operation fields only — matches the server's `toPublicStatus`
  /// shape. Callers decide how to wrap this per-endpoint response shape.
  Map<String, dynamic> _publicJson(_FakeOp op) {
    final now = DateTime.now().toUtc();
    return {
      'operationId': op.id,
      'readingType': op.readingType,
      'status': op.status,
      'durable': op.executionMode == 'durable',
      'createdAt': now.toIso8601String(),
      'readyAt': now.toIso8601String(),
      'serverNow': now.toIso8601String(),
      'waitFinished': immediatelyEligible,
      'remainingMs': immediatelyEligible ? 0 : 1,
      'resultReady': op.status == 'ready' && op.resultId != null,
      if (op.resultId != null) 'resultId': op.resultId,
      'accelerated': false,
    };
  }
}

/// A `ReadingFeatureRunner` wired to a fresh in-memory fake backend —
/// eligible to claim immediately, one claim wins per operation, exactly
/// like the real server's transactional guarantee.
ReadingFeatureRunner fakeImmediateReadingFeatureRunner({
  FakeReadingOperationBackend? backend,
  bool serverOwnedCompletion = false,
}) {
  final fake = backend ?? FakeReadingOperationBackend();
  final operations = ReadingOperationGateway(send: fake.send);
  return ReadingFeatureRunner(
    serverOwnedCompletion: serverOwnedCompletion,
    stagedImages: serverOwnedCompletion
        ? ReadingStagedImageGateway(fake.send)
        : null,
    // SMD1 — Soulmate's `submitSoulmateDurable` reads this directly off
    // the runner (unlike the legacy path, which is handed a separate
    // gateway instance via `readingOperationInputGatewayProvider`).
    inputs: ReadingOperationInputGateway(send: fake.send),
    flow: ReadingLiveFlow(
      operations: operations,
      acceleration: ReadingAccelerationClient(send: fake.send),
      send: fake.send,
    ),
  );
}

/// The structured-input counterpart to [fakeImmediateReadingFeatureRunner] —
/// pass the SAME [backend] to both so a test's orchestrator sees one
/// consistent fake server.
ReadingOperationInputGateway fakeReadingOperationInputGateway({
  FakeReadingOperationBackend? backend,
}) {
  final fake = backend ?? FakeReadingOperationBackend();
  return ReadingOperationInputGateway(send: fake.send);
}
