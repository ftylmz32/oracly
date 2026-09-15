/// Shared Coffee/Palm image normalizer — EXIF/HEIC handling regression.
///
/// Root cause under test: a camera/gallery JPEG usually carries an Exif
/// segment (often with a rotation tag). Vision APIs read raw pixel bytes and
/// never apply Exif rotation themselves, so an un-normalized photo can reach
/// the model sideways/upside-down and get correctly-but-unhelpfully judged
/// unusable (`invalid_image` for Coffee, `usable:false` for Palm). Before
/// this fix, any JPEG under the size threshold — Exif or not — took a silent
/// passthrough "fast path" that skipped orientation baking entirely.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/transport/image_normalizer.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const _messages = ImageNormalizeMessages(
  missing: 'missing',
  unreadable: 'unreadable',
  unsupported: 'unsupported',
  normalizeFailed: 'normalize_failed',
  tooLarge: 'too_large',
);

/// Minimal decodable-enough JPEG: SOI, tiny APP0/JFIF, padding (to clear the
/// normalizer's minimum-byte-size floor), then EOI. No Exif.
Uint8List _plainJpeg() => Uint8List.fromList([
      0xFF, 0xD8, // SOI
      0xFF, 0xE0, 0x00, 0x10, // APP0, length 16
      0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
      0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
      ...List.filled(9 * 1024, 0x00), // padding well past minBytes (8 KB)
      0xFF, 0xD9, // EOI
    ]);

/// Same shape but with a real APP1 "Exif" segment spliced in right after SOI.
Uint8List _jpegWithExif() {
  final plain = _plainJpeg();
  final exifSegment = Uint8List.fromList([
    0xFF, 0xE1, 0x00, 0x08, // APP1, length 8
    0x45, 0x78, 0x69, 0x66, // "Exif"
  ]);
  return Uint8List.fromList([
    ...plain.sublist(0, 2), // SOI
    ...exifSegment,
    ...plain.sublist(2), // rest (APP0 + SOS/EOI)
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('image_normalizer_test_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<String> writeFixture(Uint8List bytes, {String name = 'photo.jpg'}) async {
    final path = '${temp.path}/$name';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  test('plain JPEG without Exif takes the fast path and succeeds', () async {
    final path = await writeFixture(_plainJpeg());
    final result = await ImageNormalizer.normalize(
      CoffeeImagePick(path: path),
      'test_work',
      _messages,
    );
    expect(result.mimeType, 'image/jpeg');
    expect(await File(result.path).exists(), isTrue);
  });

  test(
    'JPEG carrying an Exif segment is never silently passed through — it '
    'must attempt real orientation-correcting normalization, not the '
    'no-op fast path (the actual pre-fix defect)',
    () async {
      final path = await writeFixture(_jpegWithExif());
      // No platform channel for flutter_image_compress in this test
      // environment, so real normalization surfaces as a normalize
      // failure — the important assertion is that it does NOT silently
      // return the unrotated original bytes as a success.
      await expectLater(
        ImageNormalizer.normalize(
          CoffeeImagePick(path: path),
          'test_work',
          _messages,
        ),
        throwsA(
          isA<ImageNormalizeException>().having(
            (e) => e.message,
            'message',
            'normalize_failed',
          ),
        ),
      );
    },
  );

  test('missing file fails fast with the missing-file message', () async {
    await expectLater(
      ImageNormalizer.normalize(
        CoffeeImagePick(path: '${temp.path}/does_not_exist.jpg'),
        'test_work',
        _messages,
      ),
      throwsA(
        isA<ImageNormalizeException>()
            .having((e) => e.message, 'message', 'missing')
            .having((e) => e.kind, 'kind', ImageNormalizeKind.corrupt),
      ),
    );
  });

  test('empty file is rejected as unreadable', () async {
    final path = await writeFixture(Uint8List(0));
    await expectLater(
      ImageNormalizer.normalize(
        CoffeeImagePick(path: path),
        'test_work',
        _messages,
      ),
      throwsA(
        isA<ImageNormalizeException>()
            .having((e) => e.message, 'message', 'unreadable'),
      ),
    );
  });

  test('unrecognized format with no claimed mime is rejected as unsupported', () async {
    final path = await writeFixture(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));
    await expectLater(
      ImageNormalizer.normalize(
        CoffeeImagePick(path: path),
        'test_work',
        _messages,
      ),
      throwsA(
        isA<ImageNormalizeException>()
            .having((e) => e.message, 'message', 'unsupported')
            .having((e) => e.kind, 'kind', ImageNormalizeKind.unsupported),
      ),
    );
  });
}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
}
