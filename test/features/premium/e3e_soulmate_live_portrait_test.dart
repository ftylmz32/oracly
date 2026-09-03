/// E3E: real Cloud Run soulmate PNG must decode and paint (no fake fallback).
/// Reuses sanitized local artifact — never calls OpenAI.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_portrait_reveal.dart';

File _portraitFile() {
  // Resolve from package root regardless of flutter test cwd.
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final candidate = File.fromUri(
      dir.uri.resolve('tool/e3e_private/evidence/soulmate_draw_portrait.png'),
    );
    if (candidate.existsSync()) return candidate;
    final pubspec = File.fromUri(dir.uri.resolve('pubspec.yaml'));
    if (pubspec.existsSync()) {
      return File.fromUri(
        dir.uri.resolve('tool/e3e_private/evidence/soulmate_draw_portrait.png'),
      );
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return File('tool/e3e_private/evidence/soulmate_draw_portrait.png');
}

void main() {
  final portraitFile = _portraitFile();

  test('E3E soulmate portrait is real 1024x1536 PNG', () async {
    expect(
      portraitFile.existsSync(),
      isTrue,
      reason: 'missing ${portraitFile.path} — restore E3E evidence artifact',
    );
    final bytes = portraitFile.readAsBytesSync();
    expect(bytes.length, greaterThan(32 * 1024));
    expect(bytes[0], 0x89);
    expect(bytes[1], 0x50);
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1024);
    expect(frame.image.height, 1536);
    frame.image.dispose();
  });

  testWidgets('E3E portrait reveal paints without overflow', (tester) async {
    expect(portraitFile.existsSync(), isTrue);
    final bytes = Uint8List.fromList(portraitFile.readAsBytesSync());

    Future<void> pumpAt(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SoulMatePortraitReveal(imageBytes: bytes),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.byType(SoulMatePortraitReveal), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    }

    await pumpAt(const Size(320, 568));
    await pumpAt(const Size(390, 844));
  });
}