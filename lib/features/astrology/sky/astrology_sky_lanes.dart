/// Gives each reading lane its own calculated aspect, strongest first.
///
/// An aspect is used by at most one lane, so love, work and money are always
/// written from different evidence. A lane may stay empty on a quiet day.
library;

import 'astrology_natal_sky.dart';
import 'astrology_transit_engine.dart';

enum SkyLane { overall, love, career, money, mood, drive, opportunity, caution }

abstract final class AstrologySkyLanes {
  AstrologySkyLanes._();

  static Map<SkyLane, TransitHit> assign(TransitSky sky) {
    final used = <String>{};
    final out = <SkyLane, TransitHit>{};
    void take(SkyLane lane, bool Function(TransitHit h) wanted) {
      for (final h in sky.hits) {
        if (!wanted(h) || used.contains(h.key)) continue;
        used.add(h.key);
        out[lane] = h;
        return;
      }
    }

    take(SkyLane.overall, (_) => true);
    take(SkyLane.love, _isLove);
    take(SkyLane.career, _isCareer);
    take(SkyLane.money, _isMoney);
    take(SkyLane.mood, (h) =>
        h.transit == SkyPoint.moon || h.natal.point == SkyPoint.moon);
    take(SkyLane.drive, (h) =>
        h.transit == SkyPoint.mars || h.natal.point == SkyPoint.mars);
    take(SkyLane.opportunity, (h) => h.tone == TransitTone.flow);
    take(SkyLane.caution, (h) => h.tone == TransitTone.friction);
    return out;
  }

  static bool _isLove(TransitHit h) {
    const natal = {SkyPoint.venus, SkyPoint.moon, SkyPoint.mars};
    if (natal.contains(h.natal.point) && h.transit != SkyPoint.mercury) {
      return true;
    }
    return h.transit == SkyPoint.venus &&
        (h.natal.point == SkyPoint.sun || h.natal.point == SkyPoint.ascendant);
  }

  static bool _isCareer(TransitHit h) {
    const natal = {
      SkyPoint.sun,
      SkyPoint.midheaven,
      SkyPoint.saturn,
      SkyPoint.mercury,
    };
    const moving = {
      SkyPoint.sun,
      SkyPoint.mars,
      SkyPoint.jupiter,
      SkyPoint.saturn,
      SkyPoint.mercury,
    };
    if (natal.contains(h.natal.point) && moving.contains(h.transit)) {
      return true;
    }
    return h.natal.point == SkyPoint.mars &&
        (h.transit == SkyPoint.saturn || h.transit == SkyPoint.jupiter);
  }

  static bool _isMoney(TransitHit h) {
    const moving = {SkyPoint.venus, SkyPoint.jupiter, SkyPoint.saturn};
    const natal = {
      SkyPoint.venus,
      SkyPoint.jupiter,
      SkyPoint.saturn,
      SkyPoint.mercury,
    };
    return moving.contains(h.transit) && natal.contains(h.natal.point);
  }
}
