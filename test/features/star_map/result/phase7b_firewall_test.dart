/// Phase 7B — presentation firewall (static): the typed contract cannot be
/// bypassed, and reopen / result chrome stays free of provider, astronomy and
/// raw-payload parsing.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _resultDir = 'lib/features/star_map/result';
const _referenceDir = 'lib/features/star_map/presentation/reference';
const _screen = '$_referenceDir/star_map_reference_result_screen.dart';
const _presentationModel = '$_resultDir/yildizname_result_presentation.dart';

List<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String _norm(String path) => path.replaceAll('\\', '/');

/// Source without line / doc comments — comments may mention `.name`.
String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

/// Files that make up the 7B presentation path.
List<String> get _presentationPathFiles => [
  for (final f in _dartFiles(_resultDir)) _norm(f.path),
  '$_referenceDir/star_map_scope_note.dart',
  '$_referenceDir/star_map_artifact_reopen_screen.dart',
  _screen,
  'lib/features/star_map/artifacts/yildizname_artifact_presentation.dart',
];

void main() {
  test('unscoped compatibility path has no production caller', () {
    for (final f in _dartFiles('lib')) {
      final path = _norm(f.path);
      if (path == _screen || path == _presentationModel) continue;
      final text = f.readAsStringSync();
      expect(
        text.contains('.unscoped('),
        isFalse,
        reason: '$path must use the typed presentation, not .unscoped',
      );
    }
  });

  test('every production result screen receives a typed presentation', () {
    final call = RegExp(r'StarMapReferenceResultScreen\(');
    for (final f in _dartFiles('lib')) {
      final path = _norm(f.path);
      if (path == _screen) continue;
      final text = f.readAsStringSync();
      for (final m in call.allMatches(text)) {
        final tail = text.substring(m.end, (m.end + 240).clamp(0, text.length));
        expect(
          tail.contains('presentation:'),
          isTrue,
          reason: '$path passes raw title/sections to the result screen',
        );
      }
    }
  });

  test('exactly one result screen class exists (no parallel owner)', () {
    final screens = <String>[];
    for (final f in _dartFiles('lib/features/star_map')) {
      final text = f.readAsStringSync();
      if (RegExp(r'class\s+\w*Result\w*Screen\b').hasMatch(text)) {
        screens.add(_norm(f.path));
      }
    }
    expect(screens, [_screen]);
  });

  test('raw enum / wire label derivation is gone', () {
    for (final f in _dartFiles('lib')) {
      expect(
        f.readAsStringSync().contains('sectionChromeTitle'),
        isFalse,
        reason: _norm(f.path),
      );
    }
  });

  test('chrome never derives labels from enum names', () {
    for (final path in _presentationPathFiles) {
      final text = _code(path);
      expect(
        RegExp(r'\.name\b').hasMatch(text),
        isFalse,
        reason: '$path reads an enum .name',
      );
    }
  });

  test('presentation path never imports provider / astronomy / network', () {
    const forbidden = [
      'astronomy',
      'natal_chart_calculator',
      '/ai/',
      'narrative/live',
      'proxy',
      'http',
      'openai',
      'dart:io',
      'gems',
    ];
    final imp = RegExp(r"import\s+'([^']+)'");
    for (final path in _presentationPathFiles) {
      for (final m in imp.allMatches(_code(path))) {
        final target = m.group(1)!;
        // Pure reading-context model already imported by the pre-7B screen.
        if (target.endsWith('oracle_reading_context.dart')) continue;
        for (final bad in forbidden) {
          expect(
            target.contains(bad),
            isFalse,
            reason: '$path imports "$target" (matches "$bad")',
          );
        }
      }
    }
  });

  test('widgets never parse artifact / request payloads', () {
    const needles = [
      'YildiznameNarrativePayload',
      'omittedLayers',
      "['request']",
      "['result']",
      'fidelity',
      'payload[',
    ];
    for (final f in _dartFiles(_referenceDir)) {
      final text = f.readAsStringSync();
      for (final n in needles) {
        expect(
          text.contains(n),
          isFalse,
          reason: '${_norm(f.path)} parses raw payload via "$n"',
        );
      }
    }
  });

  test('production presentation code hard-codes no product label', () {
    for (final path in _presentationPathFiles) {
      expect(
        _code(path).contains("'Yıldızname'"),
        isFalse,
        reason: '$path hard-codes the product label',
      );
    }
  });
}
