/// G1 — shared fakes: a transport that can drop calls on top of the
/// in-memory reading backend, and server-completed analysis ports.
library;

import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_feature_runner.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_input_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../support/fake_reading_operation_backend.dart';

/// Drops the next N calls of a kind the way a dead network does (null
/// wire), so recovery code sees "unreachable", never "gone".
class G1FlakyTransport {
  G1FlakyTransport(this.backend);

  final FakeReadingOperationBackend backend;
  int dropActive = 0;
  int dropExact = 0;
  int dropResult = 0;
  bool dropQuotes = false;
  int activeCalls = 0;
  int creates = 0;

  static final _exact = RegExp(r'^/v1/reading-operations/[a-f0-9]{32}$');

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    if (method == 'POST' && path == '/v1/reading-operations') creates++;
    if (path.startsWith('/v1/reading-flow/active')) {
      activeCalls++;
      if (dropActive > 0) {
        dropActive--;
        return null;
      }
    } else if (method == 'GET' && _exact.hasMatch(path) && dropExact > 0) {
      dropExact--;
      return null;
    } else if (path.endsWith('/result') && dropResult > 0) {
      dropResult--;
      return null;
    } else if (method == 'GET' && path.endsWith('/accelerate') && dropQuotes) {
      return null;
    }
    return backend.send(method, path, body);
  }

  ReadingLiveFlow flow() => ReadingLiveFlow(
        operations: ReadingOperationGateway(send: send),
        acceleration: ReadingAccelerationClient(send: send),
        send: send,
      );

  ReadingFeatureRunner runner({bool serverOwnedCompletion = false}) =>
      ReadingFeatureRunner(
        serverOwnedCompletion: serverOwnedCompletion,
        stagedImages:
            serverOwnedCompletion ? ReadingStagedImageGateway(send) : null,
        inputs: ReadingOperationInputGateway(send: send),
        flow: flow(),
      );
}

class G1NoImages implements CoffeeImageInputPort {
  const G1NoImages();
  @override
  bool get cameraAvailable => false;
  @override
  bool get galleryAvailable => false;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

/// Server-owned Coffee: results only ever arrive through restoreCompleted.
class G1CompletedCoffee implements CoffeeAnalysisPort, CoffeeCompletedAnalysisPort {
  int throwNext = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) =>
      throw StateError('server-owned');

  @override
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) {
    if (throwNext > 0) {
      throwNext--;
      throw const FormatException('unreadable payload');
    }
    return g1Coffee(resultId, createdAt: persistedAt);
  }
}

class G1CompletedPalm implements PalmAnalysisPort, PalmCompletedAnalysisPort {
  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand}) =>
      throw StateError('server-owned');

  @override
  PalmReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required PalmHand hand,
    required Map<String, dynamic> result,
  }) =>
      PalmReading(
        id: resultId,
        createdAt: persistedAt,
        hand: hand,
        overall: 'server palm',
        takeaway: 'done',
      );
}

CoffeeReading g1Coffee(String id, {DateTime? createdAt}) => CoffeeReading(
      id: id,
      createdAt: createdAt ?? DateTime.utc(2026),
      overall: 'server coffee',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: 'done',
    );

/// Bounded real-time wait for a condition driven by short poll intervals.
Future<void> g1Until(bool Function() done, {int maxTicks = 200}) async {
  for (var i = 0; i < maxTicks && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
