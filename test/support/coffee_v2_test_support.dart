/// Shared fixtures/fakes for Coffee V2 client-foundation tests.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/transport/image_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_byte_loader.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_normalizer.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fake_reading_operation_backend.dart';

const coffeeV2TestMessages = ImageNormalizeMessages(
  missing: 'missing',
  unreadable: 'unreadable',
  unsupported: 'unsupported',
  normalizeFailed: 'normalize_failed',
  tooLarge: 'too_large',
);

/// Minimal decodable-enough JPEG (SOI/APP0/padding/EOI, no Exif) sized so it
/// always takes `ImageNormalizer`'s no-platform-channel fast path.
Uint8List plainJpegBytes({int totalSize = 9 * 1024}) {
  final header = <int>[
    0xFF, 0xD8, // SOI
    0xFF, 0xE0, 0x00, 0x10, // APP0, length 16
    0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
    0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
  ];
  const footer = [0xFF, 0xD9]; // EOI
  final padding = totalSize - header.length - footer.length;
  return Uint8List.fromList([
    ...header,
    ...List.filled(padding < 0 ? 0 : padding, 0x00),
    ...footer,
  ]);
}

class FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProvider(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
}

/// Deterministic, injectable normalizer stand-in — lets tests control
/// size/mime/failure outcomes without depending on the real
/// `flutter_image_compress` platform channel.
class ScriptedCoffeeV2Normalizer implements CoffeeV2Normalizer {
  ScriptedCoffeeV2Normalizer(this._script);
  final Future<CoffeeImagePick> Function(CoffeeImagePick source) _script;

  @override
  Future<CoffeeImagePick> normalize(CoffeeImagePick source) =>
      _script(source);
}

/// Records byte-load and stage calls into one shared chronological log so
/// tests can prove strict load-then-stage-then-next-load ordering (never
/// two slots' bytes held, or requested, at once).
class RecordingByteLoader implements CoffeeV2ByteLoader {
  RecordingByteLoader(this.chronology);
  final List<String> chronology;

  @override
  Future<List<int>> loadBytes(String path) async {
    chronology.add('load:$path');
    return File(path).readAsBytes();
  }
}

/// Wraps a [FakeReadingOperationBackend] to add Coffee-V2-specific
/// observability on top of the SAME shared fake used by every other
/// reading-operation test: per-slot call order/count, in-flight
/// concurrency, one-shot forced failures, and (optionally) an entry into a
/// shared chronology log alongside [RecordingByteLoader].
class RecordingStagedTransport {
  RecordingStagedTransport(this.backend, {List<String>? chronology})
      : chronology = chronology ?? [];

  final FakeReadingOperationBackend backend;
  final List<String> chronology;
  final List<String> slotCallOrder = [];
  final Map<String, int> stageCallCountBySlot = {};
  final Set<String> failSlotsOnce = {};
  int _inFlight = 0;
  int maxConcurrentObserved = 0;

  static final _stagePathPattern = RegExp(r'/staged-image$');

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    final isStage = method == 'POST' && _stagePathPattern.hasMatch(path);
    if (!isStage) return backend.send(method, path, body);

    final slot = body?['slot'] as String?;
    if (slot != null) {
      slotCallOrder.add(slot);
      stageCallCountBySlot[slot] = (stageCallCountBySlot[slot] ?? 0) + 1;
      chronology.add('stage:$slot');
    }
    _inFlight++;
    if (_inFlight > maxConcurrentObserved) maxConcurrentObserved = _inFlight;
    try {
      // Real async gap: if the caller ever parallelized stage calls, two
      // would be in flight across this yield and maxConcurrentObserved
      // would exceed 1.
      await Future<void>.delayed(Duration.zero);
      if (slot != null && failSlotsOnce.remove(slot)) {
        return const ReadingOperationWire(statusCode: 500, json: null);
      }
      return await backend.send(method, path, body);
    } finally {
      _inFlight--;
    }
  }
}
