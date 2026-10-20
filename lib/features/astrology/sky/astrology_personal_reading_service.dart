/// Today's personal astrology: calculated sky in, written reading out.
///
/// Order: compute the sky → same-day cached text → writer → client checks →
/// cache. Any failure (offline, quota, spend guard, a refused text, an
/// account switch mid-flight) returns null, and the caller shows the
/// general sign reading labelled as general.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../ai/production/oracly_astrology_daily_ai_service.dart';
import '../../birth_chart/astronomy/astronomical_ephemeris_port.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../models/astrology_daily_reading.dart';
import 'astrology_daily_cache.dart';
import 'astrology_daily_request.dart';
import 'astrology_daily_result.dart';
import 'astrology_natal_sky.dart';
import 'astrology_transit_engine.dart';

class AstrologyPersonalReadingService {
  AstrologyPersonalReadingService({
    required LocalStorage storage,
    required String? Function() ownerId,
    required AstronomicalEphemerisPort ephemeris,
    this.ai,
  })  : _cache = AstrologyDailyCache(storage),
        _ownerId = ownerId,
        _ephemeris = ephemeris;

  final AstrologyDailyCache _cache;
  final String? Function() _ownerId;
  final AstronomicalEphemerisPort _ephemeris;
  final OraclyAstrologyDailyAiService? ai;

  Future<AstrologyDailyReading?> load({
    required AstrologyNatalSky natal,
    required DateTime day,
    List<String> themes = const [],
    String? addressName,
  }) async {
    final owner = _ownerId()?.trim() ?? '';
    if (owner.isEmpty) return null;
    final labels = [
      for (final t in themes) DiscoveryTheme.resolve(t)?.localized ?? t.trim(),
    ].where((t) => t.isNotEmpty).toList();
    final sky = AstrologyTransitEngine.compute(
      natal: natal,
      day: day,
      ephemeris: _ephemeris,
    );
    final request = AstrologyDailyRequest.build(
      sky: sky,
      day: day,
      themes: labels,
      addressName: addressName,
    );
    AstrologyDailyReading reading(Map<String, String> fields) =>
        AstrologyDailyResult.toReading(
          fields,
          depth: request.depth,
          themes: themes,
        );

    final cached = _cache.read(ownerId: owner, operationId: request.operationId);
    if (cached != null) {
      try {
        return reading(AstrologyDailyResult.validate(
          {...cached, 'contractVersion': kAstrologyDailyResultVersion},
          depth: request.depth,
          addressName: request.addressName,
        ));
      } catch (_) {
        // A stored text that no longer passes is rewritten below.
      }
    }

    final writer = ai;
    if (writer == null) return null;
    try {
      final outcome = await writer.generateAstrologyDaily(
        payload: request.payload,
        operationId: request.operationId,
      );
      final value = outcome.value;
      if (value == null) return null;
      final fields = AstrologyDailyResult.validate(
        value,
        depth: request.depth,
        addressName: request.addressName,
      );
      // Never file one account's reading under another.
      if ((_ownerId()?.trim() ?? '') != owner) return null;
      await _cache.write(
        ownerId: owner,
        operationId: request.operationId,
        fields: fields,
      );
      return reading(fields);
    } catch (_) {
      return null;
    }
  }
}
