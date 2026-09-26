/// Phase 7C — fact layer firewall (static): facts come from the stored request
/// through ONE projector, the widget only renders finished strings, and no
/// provider / astronomy / profile / clock can reach the fact path.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';

const _resultDir = 'lib/features/star_map/result';
const _referenceDir = 'lib/features/star_map/presentation/reference';
const _plate = '$_referenceDir/star_map_fact_snapshot_plate.dart';
const _screen = '$_referenceDir/star_map_reference_result_screen.dart';
const _adapter =
    'lib/features/star_map/artifacts/yildizname_artifact_presentation.dart';
const _projector = '$_resultDir/yildizname_fact_projector.dart';

String _norm(String p) => p.replaceAll('\\', '/');

String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

List<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// Every file that makes up the Phase 7C fact path.
List<String> get _factPathFiles => [
  for (final f in _dartFiles(_resultDir))
    if (_norm(f.path).contains('yildizname_fact_')) _norm(f.path),
  'lib/core/l10n/tables/table_star_facts.dart',
  _plate,
];

void main() {
  test('the fact path exists as designed', () {
    expect(
      _factPathFiles.where((p) => p.contains('yildizname_fact_')),
      hasLength(3),
      reason: 'snapshot · chrome · projector',
    );
    expect(File(_plate).existsSync(), isTrue);
  });

  test(
    'the fact path never imports provider / astronomy / profile / network',
    () {
      const forbidden = [
        'astronomy',
        'natal_chart_calculator',
        '/ai/',
        'narrative/live',
        'birth_profile',
        'birth_chart',
        'birth_information',
        'riverpod',
        'proxy',
        'http',
        'openai',
        'dart:io',
        'gems',
        'storage',
        'shared_preferences',
        'artifacts/',
      ];
      final imp = RegExp(r"import\s+'([^']+)'");
      for (final path in _factPathFiles) {
        for (final m in imp.allMatches(_code(path))) {
          final target = m.group(1)!;
          for (final bad in forbidden) {
            expect(
              target.contains(bad),
              isFalse,
              reason: '$path imports "$target" (matches "$bad")',
            );
          }
        }
      }
    },
  );

  test('the fact path derives no label from an enum .name', () {
    for (final path in _factPathFiles) {
      expect(
        RegExp(r'\.name\b').hasMatch(_code(path)),
        isFalse,
        reason: '$path reads an enum .name',
      );
    }
  });

  test('the projector is a pure function — no clock, no randomness', () {
    final code = _code(_projector);
    for (final needle in const [
      'DateTime',
      'Random',
      'Platform.',
      'Stopwatch',
      'Timer',
      'await ',
      'Future',
    ]) {
      expect(code.contains(needle), isFalse, reason: needle);
    }
  });

  test(
    'the widget renders finished strings only — it never reads a request',
    () {
      final code = _code(_plate);
      for (final needle in const [
        'factRef',
        'certainty',
        'omittedLayers',
        'fidelity',
        'degreeWithinSign',
        'houseSystem',
        'Map<String',
        'dynamic',
        "['",
        'YildiznameNarrativePayload',
        'YildiznameFactProjector',
        'YildiznameFactChrome',
        'YildiznameScopeResolver',
        'OraclyL10n',
      ]) {
        expect(code.contains(needle), isFalse, reason: 'plate reads "$needle"');
      }
      final imp = RegExp(r"import\s+'([^']+)'");
      for (final m in imp.allMatches(code)) {
        final target = m.group(1)!;
        final allowed =
            target.startsWith('package:flutter/') ||
            target.contains('core/design_system/') ||
            target.contains('core/theme/') ||
            target.endsWith('result/yildizname_fact_snapshot.dart');
        expect(allowed, isTrue, reason: 'plate imports "$target"');
      }
    },
  );

  test(
    'exactly one production caller projects facts: the artifact adapter',
    () {
      final callers = <String>[];
      for (final f in _dartFiles('lib')) {
        final path = _norm(f.path);
        if (path == _projector) continue;
        if (_code(path).contains('YildiznameFactProjector.project(')) {
          callers.add(path);
        }
      }
      expect(callers, [_adapter]);
    },
  );

  test(
    'the canonical screen renders the plate but never builds facts itself',
    () {
      final code = _code(_screen);
      expect(code.contains('YildiznameFactProjector'), isFalse);
      expect(code.contains('YildiznameNarrativePayload'), isFalse);
      expect(code.contains('StarMapFactSnapshotPlate('), isTrue);
      expect(
        code.contains('presentation.factSnapshot'),
        isTrue,
        reason: 'the plate reads the typed presentation, nothing else',
      );
    },
  );

  test(
    'visual order in the screen: scope note → facts → sections → footer',
    () {
      final code = _code(_screen);
      final note = code.indexOf('StarMapScopeNote(');
      final plate = code.indexOf('StarMapFactSnapshotPlate(');
      final sections = code.indexOf('StarMapResultSectionCard(');
      final footer = code.indexOf('StarMapResultFooter(');
      expect(note, greaterThan(0));
      expect(plate, greaterThan(note));
      expect(sections, greaterThan(plate));
      expect(footer, greaterThan(sections));
    },
  );

  test('no parallel fact plate / result screen was created', () {
    final plates = <String>[];
    final screens = <String>[];
    for (final f in _dartFiles('lib/features/star_map')) {
      final text = f.readAsStringSync();
      if (RegExp(r'class\s+\w*FactSnapshotPlate\b').hasMatch(text)) {
        plates.add(_norm(f.path));
      }
      if (RegExp(r'class\s+\w*Result\w*Screen\b').hasMatch(text)) {
        screens.add(_norm(f.path));
      }
    }
    expect(plates, [_plate]);
    expect(screens, [_screen]);
  });

  test('the presentation adapter still reads no profile or chart', () {
    final code = _code(_adapter);
    for (final needle in const [
      'BirthProfile',
      'birthInformation',
      'NatalChartCalculator',
      'ChartRepository',
      'DateTime.now',
    ]) {
      expect(code.contains(needle), isFalse, reason: needle);
    }
  });

  test('fact chrome keys exist in TR / EN / RU with real copy', () {
    const keys = [
      'star.fact.title',
      'star.fact.more',
      'star.fact.outer',
      'star.fact.aspects',
      'star.fact.midheaven',
      'star.fact.retrograde',
      'star.fact.house',
      'star.fact.balance.element',
      'star.fact.balance.quality',
      'star.fact.quality.cardinal',
      'star.fact.quality.fixed',
      'star.fact.quality.mutable',
    ];
    for (final lang in const ['tr', 'en', 'ru']) {
      final seen = <String>{};
      for (final key in keys) {
        final text = OraclyL10n.t(key, languageCode: lang);
        expect(text.trim(), isNotEmpty, reason: '$lang $key');
        expect(text, isNot(key), reason: '$lang $key resolves to its key');
        expect(text.contains('TODO'), isFalse);
        seen.add(text);
      }
      expect(seen.length, keys.length, reason: '$lang has duplicate copy');
      expect(
        OraclyL10n.t('star.fact.house', languageCode: lang),
        contains('{n}'),
      );
    }
    // Language-specific script, so no locale silently falls back.
    final cyr = RegExp(r'[А-Яа-яЁё]');
    for (final key in keys) {
      expect(
        cyr.hasMatch(OraclyL10n.t(key, languageCode: 'ru')),
        isTrue,
        reason: key,
      );
      expect(
        cyr.hasMatch(OraclyL10n.t(key, languageCode: 'en')),
        isFalse,
        reason: key,
      );
      expect(
        cyr.hasMatch(OraclyL10n.t(key, languageCode: 'tr')),
        isFalse,
        reason: key,
      );
    }
  });

  test('zodiac, planet and aspect names are reused, not re-translated', () {
    final tables = _code('lib/core/l10n/tables/table_star_facts.dart');
    for (final reused in const ['zodiac.', "'planet.", 'aspect.']) {
      expect(
        tables.contains("'$reused") || tables.contains(reused),
        isFalse,
        reason: 'table_star_facts must not redefine "$reused*"',
      );
    }
  });
}
