/// Phase 7E — static firewalls for typed result actions.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _footer =
    'lib/features/star_map/presentation/reference/star_map_result_footer.dart';
const _screen =
    'lib/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
const _body =
    'lib/features/star_map/presentation/reference/star_map_result_body_children.dart';
const _builder =
    'lib/features/star_map/result/yildizname_result_actions_builder.dart';

String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  test('footer does not rebuild share/copy/favorite/OR payloads', () {
    final code = _code(_footer);
    expect(code.contains('StarMapInsightCopy.fromResult'), isFalse);
    expect(code.contains('DiscoveryShareBuilder.starMap'), isFalse);
    expect(code.contains('FavoriteMomentFactory'), isFalse);
    expect(code.contains('DateTime.now'), isFalse);
    expect(code.contains('sourceUnavailable'), isFalse);
    expect(code.contains('YildiznameArtifactOrContext'), isFalse);
    expect(code.contains('YildiznameResultActions'), isTrue);
    expect(code.contains('this.actions'), isTrue);
  });

  test('screen does not derive insight or parallel readingContext', () {
    final code = _code(_screen);
    expect(code.contains('sections.first'), isFalse);
    expect(
      RegExp(r'final\s+OracleReadingContext\??\s+readingContext').hasMatch(code),
      isFalse,
    );
    expect(code.contains('StarMapResultBodyChildren.build'), isTrue);
  });

  test('body children pass presentation.actions only', () {
    final code = _code(_body);
    expect(code.contains('actions: presentation.actions'), isTrue);
    expect(code.contains('artifactId:'), isFalse);
    expect(code.contains('readingContext:'), isFalse);
    expect(code.contains('insight:'), isFalse);
  });

  test('actions builder reuses canonical sanitizers', () {
    final code = _code(_builder);
    expect(code.contains('StarMapInsightCopy.fromResult'), isTrue);
    expect(code.contains('DiscoveryShareBuilder.starMap'), isTrue);
    expect(code.contains('YildiznameCanonicalInsight.of'), isTrue);
    expect(code.contains('DateTime.now'), isFalse);
  });

  test('forensic footer chrome is isolated from production footer', () {
    final production = _code(_footer);
    expect(production.contains('sourceUnavailable'), isFalse);
    expect(production.contains('StarMapResultFooterForensic'), isTrue);
    final forensic = _code(
      'lib/features/star_map/presentation/reference/'
      'star_map_result_footer_forensic.dart',
    );
    expect(forensic.contains('sourceUnavailable'), isTrue);
  });
}
