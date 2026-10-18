/// Production gate for the single final provider reading, when it exists.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_validator.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_voice.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_angle_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_aspect_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_balance_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_house_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

const _dir = r'D:\ORACLY_KONTROL_20261016\yorum_kalitesi';

void main() {
  test('saved request has no birth data and the reading clears the gate', () {
    final requestFile = File('$_dir/YILDIZNAME_FINAL_ISTEK.json');
    final hamFile = File('$_dir/YILDIZNAME_FINAL_HAM_YANIT.json');
    if (!requestFile.existsSync()) {
      markTestSkipped('request not written yet');
      return;
    }
    final requestJson = requestFile.readAsStringSync();
    for (final key in const [
      'birthDate',
      'birthTime',
      'birthPlace',
      'latitude',
      'longitude',
      'ownerId',
    ]) {
      expect(requestJson.contains('"$key"'), isFalse, reason: key);
    }
    if (!hamFile.existsSync()) {
      markTestSkipped('provider response not written yet');
      return;
    }
    final ham = jsonDecode(hamFile.readAsStringSync()) as Map<String, dynamic>;
    expect(ham['providerCalls'], 1);
    final data = jsonDecode(ham['content'] as String) as Map<String, dynamic>;
    final result = YildiznameResultParser.parse(data);
    final request = _request(jsonDecode(requestJson) as Map<String, dynamic>);
    YildiznameQualityValidator.validate(request: request, result: result);
    expect(
      YildiznameQualityVoice.inspect(request.scope, result).findings,
      isEmpty,
    );
  });
}

YildiznameNarrativeRequest _request(Map<String, dynamic> n) {
  Map<String, dynamic> map(Object? raw) => Map<String, dynamic>.from(raw as Map);
  Map<String, int> counts(Object? raw) => {
        for (final e in (raw as Map).entries)
          e.key as String: (e.value as num).toInt(),
      };
  return YildiznameNarrativeRequest(
    languageCode: n['languageCode'] as String,
    scope: YildiznameNarrativeScope.values.byName(n['scope'] as String),
    fidelity: n['fidelity'] as String,
    houseSystem: n['houseSystem'] as String?,
    calculationVersion: n['calculationVersion'] as String?,
    placements: [
      for (final raw in n['placements'] as List)
        YildiznamePlacementFact(
          factRef: map(raw)['factRef'] as String,
          body: map(raw)['body'] as String,
          sign: map(raw)['sign'] as String,
          certainty: map(raw)['certainty'] as String,
          degreeWithinSign: (map(raw)['degreeWithinSign'] as num?)?.toDouble(),
          retrograde: map(raw)['retrograde'] as bool?,
          house: map(raw)['house'] as int?,
        ),
    ],
    angles: [
      for (final raw in n['angles'] as List)
        YildiznameAngleFact(
          factRef: map(raw)['factRef'] as String,
          kind: map(raw)['kind'] as String,
          sign: map(raw)['sign'] as String,
          certainty: map(raw)['certainty'] as String,
          degreeWithinSign: (map(raw)['degreeWithinSign'] as num).toDouble(),
          house: map(raw)['house'] as int,
        ),
    ],
    houses: [
      for (final raw in n['houses'] as List)
        YildiznameHouseFact(
          factRef: map(raw)['factRef'] as String,
          number: map(raw)['number'] as int,
          sign: map(raw)['sign'] as String,
        ),
    ],
    aspects: [
      for (final raw in n['aspects'] as List)
        YildiznameAspectFact(
          factRef: map(raw)['factRef'] as String,
          bodyA: map(raw)['bodyA'] as String,
          bodyB: map(raw)['bodyB'] as String,
          type: map(raw)['type'] as String,
          orb: (map(raw)['orb'] as num).toDouble(),
          certainty: map(raw)['certainty'] as String,
        ),
    ],
    balances: [
      for (final raw in n['balances'] as List)
        YildiznameBalanceFact(
          factRef: map(raw)['factRef'] as String,
          kind: map(raw)['kind'] as String,
          counts: counts(map(raw)['counts']),
          dominant: map(raw)['dominant'] as String?,
        ),
    ],
    discoveryThemes: [
      for (final raw in n['discoveryThemes'] as List)
        YildiznameThemeFact(
          themeRef: map(raw)['themeRef'] as String,
          label: map(raw)['label'] as String,
        ),
    ],
    omittedLayers: [
      for (final raw in n['omittedLayers'] as List) raw as String,
    ],
  );
}
