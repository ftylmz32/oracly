/// Phase 4 — SHA-256 evidence fingerprint (no owner/locale/narrative).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/birth_profile.dart';

abstract final class EvidenceFingerprint {
  EvidenceFingerprint._();

  static String of(BirthProfile p) {
    final time = p.hasKnownTime && p.birthTime != null
        ? '${p.birthTime!.hour.toString().padLeft(2, '0')}:'
            '${p.birthTime!.minute.toString().padLeft(2, '0')}'
        : 'unknown';
    final buf = StringBuffer()
      ..write('d=${p.birthDate.year.toString().padLeft(4, '0')}-')
      ..write('${p.birthDate.month.toString().padLeft(2, '0')}-')
      ..write('${p.birthDate.day.toString().padLeft(2, '0')};')
      ..write('t=$time;')
      ..write('tk=${p.birthTimeKnown};')
      ..write('place=${p.birthPlaceId ?? p.birthPlace};')
      ..write('lat=${p.latitude};')
      ..write('lon=${p.longitude};')
      ..write('tz=${p.timezoneId}');
    return sha256.convert(utf8.encode(buf.toString())).toString();
  }
}
