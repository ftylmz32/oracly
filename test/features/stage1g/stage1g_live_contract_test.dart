import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';

Map<String, dynamic> load(String name) {
  final file = File('backend/tests/fixtures/stage1g/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  test('real tarot JSON reaches the client parser intact', () {
    final data = load('tarot.json');
    final result = NarrativeTarotResultParser.parse(data);
    expect(result.languageCode, 'tr');
    expect(result.cardReadings.single.cardId, 'major_02');
    expect(result.cardReadings.single.positionKey, 'sign');
    expect(result.synthesis, contains('Azize'));
    expect(result.closingMessage.trim(), isNotEmpty);
    expect(result.advice.trim(), isNotEmpty);
  });

  test('real yıldızname JSON keeps the fictional chart sections', () {
    final data = load('yildizname.json');
    final result = YildiznameResultParser.parse(data);
    expect(result.languageCode, 'tr');
    expect(result.scope.name, 'full');
    expect(result.summary.factRefs, contains('placement.sun'));
    expect(result.summary.factRefs, contains('angle.ascendant'));
    expect(result.sections.map((s) => s.kind.wireName), contains('core_identity'));
    expect(result.closingMessage.trim(), isNotEmpty);
    expect(result.summary.factRefs.join(' '), isNot(contains('venus')));
  });

  test('a missing tarot closing is still rejected', () {
    final data = load('tarot.json');
    data.remove('closingMessage');
    expect(
      () => NarrativeTarotResultParser.parse(data),
      throwsA(isA<Object>()),
    );
  });
}
