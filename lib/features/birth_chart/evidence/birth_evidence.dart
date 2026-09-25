/// Phase 3 — typed birth evidence view (production).
library;

import '../models/birth_profile.dart';
import 'birth_timezone_status.dart';

class BirthEvidence {
  const BirthEvidence({
    required this.ownerId,
    this.birthDate,
    this.birthTime,
    this.timeKnown = false,
    this.birthPlace = '',
    this.cityId,
    this.latitude,
    this.longitude,
    this.timezoneId,
    this.timezoneStatus = BirthTimezoneStatus.missing,
    this.birthPlaceUnknownConfirmed = false,
  });

  final String? ownerId;
  final DateTime? birthDate;
  final DateTime? birthTime;
  final bool timeKnown;
  final String birthPlace;
  final String? cityId;
  final double? latitude;
  final double? longitude;
  final String? timezoneId;
  final BirthTimezoneStatus timezoneStatus;
  final bool birthPlaceUnknownConfirmed;

  bool get hasDate => birthDate != null;
  bool get hasKnownTime => timeKnown && birthTime != null;

  bool get hasValidPlaceEvidence {
    final placeOk = birthPlace.trim().isNotEmpty;
    final coordsOk = latitude != null && longitude != null;
    final tzOk =
        timezoneId != null &&
        timezoneId!.trim().isNotEmpty &&
        timezoneStatus == BirthTimezoneStatus.resolved;
    return placeOk && coordsOk && tzOk;
  }

  factory BirthEvidence.fromProfile(
    BirthProfile profile, {
    String? ownerId,
  }) {
    return BirthEvidence(
      ownerId: ownerId,
      birthDate: profile.birthDate,
      birthTime: profile.birthTime,
      timeKnown: profile.birthTimeKnown,
      birthPlace: profile.birthPlace,
      cityId: profile.birthPlaceId,
      latitude: profile.latitude,
      longitude: profile.longitude,
      timezoneId: profile.timezoneId,
      timezoneStatus: profile.timezoneResolutionStatus,
      birthPlaceUnknownConfirmed: profile.birthPlaceUnknownConfirmed,
    );
  }
}
