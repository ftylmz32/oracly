/// Phase 4 — astronomia 1.1.1 adapter (public APIs only).
///
/// Convention: geocentric tropical apparent ecliptic longitude of date.
/// Sun: [solar.apparentVSOP87]
/// Moon: [moonposition.position] + nutation Δψ
/// Mercury–Neptune: [elliptic.position] → [coord.eqToEcl]
/// Pluto: heliocentric chapter 37 → geocentric ecliptic (light-time 1-pass)
library;

import 'dart:math' as math;

import 'package:astronomia/astronomia.dart';
import 'package:astronomia/coord.dart' as coord;
import 'package:astronomia/elliptic.dart' as elliptic;
import 'package:astronomia/moonposition.dart' as moon;
import 'package:astronomia/nutation.dart' as nut;
import 'package:astronomia/planetposition.dart';
import 'package:astronomia/pluto.dart' as pluto;
import 'package:astronomia/sidereal.dart' as sidereal;
import 'package:astronomia/solar.dart' as solar;

import 'astronomical_ephemeris_port.dart';
import 'astronomical_provenance.dart';
import 'longitude_math.dart';
import 'natal_body.dart';

class AstronomiaEphemerisAdapter implements AstronomicalEphemerisPort {
  AstronomiaEphemerisAdapter();

  static const version = '1.1.1';
  final Planet _earth = Planet(planetEarth);

  @override
  String get engineId => AstronomicalProvenance.engineAstronomia;

  @override
  String get engineVersion => version;

  double _jde(DateTime utc) {
    final u = utc.toUtc();
    final day =
        u.day + (u.hour + u.minute / 60 + u.second / 3600) / 24;
    return calendarGregorianToJD(u.year, u.month, day);
  }

  @override
  double longitude(NatalBody body, DateTime utc) {
    final jde = _jde(utc);
    return LongitudeMath.normalize(switch (body) {
      NatalBody.sun => toDeg(solar.apparentVSOP87(_earth, jde).lon),
      NatalBody.moon => _moonApparent(jde),
      NatalBody.mercury => _planetLon(planetMercury, jde),
      NatalBody.venus => _planetLon(planetVenus, jde),
      NatalBody.mars => _planetLon(planetMars, jde),
      NatalBody.jupiter => _planetLon(planetJupiter, jde),
      NatalBody.saturn => _planetLon(planetSaturn, jde),
      NatalBody.uranus => _planetLon(planetUranus, jde),
      NatalBody.neptune => _planetLon(planetNeptune, jde),
      NatalBody.pluto => _plutoLon(jde),
    });
  }

  double _moonApparent(double jde) {
    final pos = moon.position(jde);
    final n = nut.nutation(jde);
    return toDeg(pos.lon + n.dPsi);
  }

  double _planetLon(int id, double jde) {
    final eq = elliptic.position(Planet(id), _earth, jde);
    final n = nut.nutation(jde);
    final eps = nut.meanObliquity(jde) + n.dEps;
    final ecl = coord.eqToEcl(eq.ra, eq.dec, math.sin(eps), math.cos(eps));
    return toDeg(ecl.lon);
  }

  double _plutoLon(double jde) {
    final lightDays = 0.0;
    final ph = pluto.heliocentric(jde - lightDays);
    final eh = _earth.position(jde);
    final px = ph.r * math.cos(ph.lat) * math.cos(ph.lon);
    final py = ph.r * math.cos(ph.lat) * math.sin(ph.lon);
    final ex = eh.range * math.cos(eh.lat) * math.cos(eh.lon);
    final ey = eh.range * math.cos(eh.lat) * math.sin(eh.lon);
    final gx = px - ex, gy = py - ey;
    var lon = math.atan2(gy, gx);
    final n = nut.nutation(jde);
    lon += n.dPsi;
    return toDeg(lon);
  }

  @override
  double apparentSiderealTime(DateTime utc) {
    final sec = sidereal.apparent(_jde(utc));
    return LongitudeMath.normalize(sec / 86400 * 360) * math.pi / 180;
  }

  @override
  double trueObliquity(DateTime utc) {
    final jde = _jde(utc);
    final n = nut.nutation(jde);
    return nut.meanObliquity(jde) + n.dEps;
  }
}
