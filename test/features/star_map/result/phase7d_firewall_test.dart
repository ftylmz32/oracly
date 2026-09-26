/// Phase 7D — static firewalls for role renderer + continuity truth.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';

const _card =
    'lib/features/star_map/presentation/reference/star_map_result_section_card.dart';
const _body =
    'lib/features/star_map/presentation/reference/star_map_result_body_children.dart';
const _echo =
    'lib/features/star_map/presentation/reference/star_map_continuity_echo.dart';
const _projector =
    'lib/features/star_map/result/yildizname_continuity_projector.dart';
const _screen =
    'lib/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
const _reopen =
    'lib/features/star_map/presentation/reference/star_map_artifact_reopen_screen.dart';

String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  test('section card switches on role — not title strings', () {
    final code = _code(_card);
    expect(code.contains('switch (role)'), isTrue);
    expect(code.contains('section.title =='), isFalse);
    expect(code.contains('.name'), isFalse);
    expect(code.contains('ChamberRitualInvite'), isFalse);
  });

  test('no parallel result screen', () {
    final screens = <String>[];
    for (final f in Directory('lib/features/star_map')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final text = f.readAsStringSync();
      if (RegExp(r'class\s+\w*Result\w*Screen\b').hasMatch(text)) {
        screens.add(f.path.replaceAll('\\', '/'));
      }
    }
    expect(screens, [_screen]);
  });

  test('continuity projector reuses Phase 6 memory + identity', () {
    final code = _code(_projector);
    expect(code.contains('YildiznameArtifactMemory.recurringThemes'), isTrue);
    expect(code.contains('YildiznameThemeIdentity.keyFor'), isTrue);
    expect(code.contains('excludeSemanticFingerprint'), isTrue);
    expect(code.contains('maxThemes'), isTrue);
  });

  test('continuity widget never receives internal IDs', () {
    final code = _code(_echo);
    for (final bad in const [
      'themeKey',
      'yth_',
      'sourceArtifactIds',
      'semanticFingerprint',
      'supportCount',
      'theme.',
    ]) {
      expect(code.contains(bad), isFalse, reason: bad);
    }
  });

  test('body order places continuity after chapters before reflection', () {
    final code = _code(_body);
    final chapters = code.indexOf('for (var i = 0; i < chapters.length');
    final continuity = code.indexOf('StarMapContinuityEcho(');
    final reflections = code.indexOf('for (final s in reflections)');
    expect(chapters, greaterThan(0));
    expect(continuity, greaterThan(chapters));
    expect(reflections, greaterThan(continuity));
  });

  test('reopen uses owner-safe history and never blocks on error', () {
    final code = _code(_reopen);
    expect(code.contains('yildiznameArtifactHistoryProvider'), isTrue);
    expect(code.contains('YildiznameContinuityProjector.project'), isTrue);
    expect(code.contains('loading:'), isTrue);
    expect(code.contains('error:'), isTrue);
    expect(code.contains('YildiznameContinuityPresentation.empty'), isTrue);
    expect(code.contains('http'), isFalse);
    expect(code.contains('NatalChartCalculator'), isFalse);
  });

  test('continuity chrome keys exist TR / EN / RU', () {
    for (final lang in const ['tr', 'en', 'ru']) {
      for (final key in const [
        'star.result.continuity.heading',
        'star.result.continuity.body',
      ]) {
        final v = OraclyL10n.t(key, languageCode: lang);
        expect(v.trim().isNotEmpty, isTrue, reason: '$lang $key');
        expect(v.contains('yth_'), isFalse);
        expect(v.contains('theme.'), isFalse);
      }
    }
  });
}
