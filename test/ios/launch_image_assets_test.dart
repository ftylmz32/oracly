/// iOS LaunchImage asset set — referenced scales must not be 1x1 placeholders.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final imageset = Directory(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset',
  );

  test('Contents.json maps 1x/2x/3x to real branded PNGs', () {
    final contents = File('${imageset.path}/Contents.json');
    expect(contents.existsSync(), isTrue);
    final raw = contents.readAsStringSync();
    expect(raw, contains('"LaunchImage.png"'));
    expect(raw, contains('"LaunchImage@2x.png"'));
    expect(raw, contains('"LaunchImage@3x.png"'));
    expect(raw, isNot(contains('LaunchImage.gmail.com')));
    expect(raw, isNot(contains('LaunchImage.jpeg.com')));
  });

  test('referenced LaunchImage scale files are not 1x1 placeholders', () {
    const expected = {
      'LaunchImage.png': (150, 150),
      'LaunchImage@2x.png': (300, 300),
      'LaunchImage@3x.png': (450, 450),
    };
    for (final entry in expected.entries) {
      final file = File('${imageset.path}/${entry.key}');
      expect(file.existsSync(), isTrue, reason: entry.key);
      final size = _pngSize(file.readAsBytesSync());
      expect(size, isNot((1, 1)), reason: entry.key);
      expect(size.$1, greaterThan(1), reason: entry.key);
      expect(size.$2, greaterThan(1), reason: entry.key);
      expect(size, entry.value, reason: entry.key);
    }
  });

  test('email-named duplicate LaunchImage files are gone', () {
    expect(
      File('${imageset.path}/james.b@example.com').existsSync(),
      isFalse,
    );
    expect(
      File('${imageset.path}/nathan.k@example.net').existsSync(),
      isFalse,
    );
  });
}

(int, int) _pngSize(Uint8List bytes) {
  expect(bytes.length, greaterThan(24));
  expect(bytes[1], 0x50); // P
  expect(bytes[2], 0x4e); // N
  expect(bytes[3], 0x47); // G
  final w =
      (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  final h =
      (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  return (w, h);
}