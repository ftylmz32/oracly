/// Wire request for the daily astrology writer (`astrology_daily`).
///
/// Carries only calculated sign positions and named findings — no birth
/// date, time, place, degree or orb. Mirrors the backend contract.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../star_map/narrative/request/yildizname_address_name.dart';
import 'astrology_natal_sky.dart';
import 'astrology_sky_lanes.dart';
import 'astrology_transit_engine.dart';

const kAstrologyDailyMode = 'sky_daily_v1';
const kAstrologyDailyContractVersion = 1;
const kAstrologyDailyMaxThemes = 3;
const kAstrologyDailyMaxThemeChars = 64;

class AstrologyDailyRequest {
  const AstrologyDailyRequest({
    required this.payload,
    required this.operationId,
    required this.depth,
    this.addressName,
  });

  final Map<String, dynamic> payload;

  /// `astro.<yyyymmdd>.<facts>` — one server ritual slot per day and facts.
  final String operationId;
  final NatalSkyDepth depth;
  final String? addressName;

  static AstrologyDailyRequest build({
    required TransitSky sky,
    required DateTime day,
    List<String> themes = const [],
    String? addressName,
  }) {
    final full = sky.natal.depth == NatalSkyDepth.full;
    final name = YildiznameAddressName.sanitize(addressName);
    final lanes = AstrologySkyLanes.assign(sky);
    final dayKey = _day(day);
    final natal = <Map<String, dynamic>>[
      for (final p in sky.natal.points)
        {
          'point': p.point.name,
          'sign': p.sign.name,
          if (full) 'house': sky.natal.houseOf(p.longitude),
        },
      // Day-only charts may still know the Moon's sign when it stayed put.
      if (!full && sky.natal.moonSign != null)
        {'point': 'moon', 'sign': sky.natal.moonSign!.name},
    ];
    final skyJson = <String, dynamic>{
      'day': dayKey,
      'depth': full ? 'full' : 'dayOnly',
      'natal': natal,
      'transits': [
        for (final t in AstrologyTransitEngine.transits)
          {
            'point': t.name,
            'sign': sky.signOf(t).name,
            if (full) 'natalHouse': sky.houseOf(t),
          },
      ],
      'findings': [
        for (final e in lanes.entries) _finding(e.key, e.value),
      ],
      'themes': _themes(themes),
      if (name != null) 'addressName': name,
    };
    final facts = Map<String, dynamic>.from(skyJson)..remove('addressName');
    final digest = sha256
        .convert(utf8.encode(jsonEncode(facts)))
        .toString()
        .substring(0, 16);
    return AstrologyDailyRequest(
      payload: {
        'mode': kAstrologyDailyMode,
        'contractVersion': kAstrologyDailyContractVersion,
        'language': 'tr',
        'sky': skyJson,
      },
      operationId: 'astro.${dayKey.replaceAll('-', '')}.$digest',
      depth: sky.natal.depth,
      addressName: name,
    );
  }

  static Map<String, dynamic> _finding(SkyLane lane, TransitHit h) {
    final allowed =
        AstrologyTransitEngine.orbs[h.transit]! - h.natal.tolerance;
    final ratio = allowed <= 0 ? 1.0 : h.orb / allowed;
    return {
      'lane': lane.name,
      'transit': h.transit.name,
      'natal': h.natal.point.name,
      'aspect': h.aspect.name,
      'tone': h.tone.name,
      'strength': ratio < 0.34
          ? 'exact'
          : ratio < 0.67
              ? 'close'
              : 'wide',
      'span': switch (h.transit) {
        SkyPoint.moon => 'hours',
        SkyPoint.mars => 'week',
        SkyPoint.jupiter || SkyPoint.saturn => 'weeks',
        _ => 'days',
      },
    };
  }

  static List<String> _themes(List<String> raw) {
    final out = <String>[];
    for (final t in raw) {
      final v = t.trim();
      if (v.isEmpty || v.length > kAstrologyDailyMaxThemeChars) continue;
      if (out.contains(v)) continue;
      out.add(v);
      if (out.length == kAstrologyDailyMaxThemes) break;
    }
    return out;
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
