/// SPRINT-002 — Birth profile from onboarding (+ Phase 3 evidence metadata).
library;

import '../evidence/birth_timezone_status.dart';

class BirthProfile {
  const BirthProfile({
    required this.birthDate,
    required this.birthPlace,
    this.birthTime,
    this.birthTimeKnown = false,
    this.latitude,
    this.longitude,
    this.birthPlaceId,
    this.timezoneId,
    this.timezoneResolutionStatus = BirthTimezoneStatus.missing,
    this.birthPlaceUnknownConfirmed = false,
  });

  final DateTime birthDate;
  final String birthPlace;
  final DateTime? birthTime;
  final bool birthTimeKnown;
  final double? latitude;
  final double? longitude;

  /// Catalogue city id when selected from picker.
  final String? birthPlaceId;
  final String? timezoneId;
  final BirthTimezoneStatus timezoneResolutionStatus;

  /// User explicitly continued without providing place.
  final bool birthPlaceUnknownConfirmed;

  bool get hasKnownTime => birthTimeKnown && birthTime != null;

  Map<String, dynamic> toJson() => {
        'birthDate': birthDate.toIso8601String(),
        'birthPlace': birthPlace,
        if (birthTime != null) 'birthTime': birthTime!.toIso8601String(),
        'birthTimeKnown': birthTimeKnown,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (birthPlaceId != null) 'birthPlaceId': birthPlaceId,
        if (timezoneId != null) 'timezoneId': timezoneId,
        'timezoneResolutionStatus': timezoneResolutionStatus.wireName,
        'birthPlaceUnknownConfirmed': birthPlaceUnknownConfirmed,
      };

  factory BirthProfile.fromJson(Map<String, dynamic> json) {
    final timeKnown = json['birthTimeKnown'] as bool? ?? false;
    DateTime? time = json['birthTime'] != null
        ? DateTime.parse(json['birthTime'] as String)
        : null;
    // Stale time with unknown → clear (honest normalize on decode).
    if (!timeKnown) time = null;

    final placeUnknown = json['birthPlaceUnknownConfirmed'] as bool? ?? false;
    String place = json['birthPlace'] as String? ?? '';
    String? placeId = json['birthPlaceId'] as String?;
    double? lat = (json['latitude'] as num?)?.toDouble();
    double? lon = (json['longitude'] as num?)?.toDouble();
    String? tz = json['timezoneId'] as String?;
    var tzStatus = BirthTimezoneStatusCodec.fromWire(
      json['timezoneResolutionStatus'] as String?,
    );
    if (placeUnknown) {
      place = '';
      placeId = null;
      lat = null;
      lon = null;
      tz = null;
      tzStatus = BirthTimezoneStatus.missing;
    }

    return BirthProfile(
      birthDate: DateTime.parse(json['birthDate'] as String),
      birthPlace: place,
      birthTime: time,
      birthTimeKnown: timeKnown,
      latitude: lat,
      longitude: lon,
      birthPlaceId: placeId,
      timezoneId: tz,
      timezoneResolutionStatus: tzStatus,
      birthPlaceUnknownConfirmed: placeUnknown,
    );
  }

  BirthProfile copyWith({
    DateTime? birthDate,
    String? birthPlace,
    DateTime? birthTime,
    bool clearBirthTime = false,
    bool? birthTimeKnown,
    double? latitude,
    double? longitude,
    bool clearCoords = false,
    String? birthPlaceId,
    bool clearBirthPlaceId = false,
    String? timezoneId,
    bool clearTimezoneId = false,
    BirthTimezoneStatus? timezoneResolutionStatus,
    bool? birthPlaceUnknownConfirmed,
  }) {
    return BirthProfile(
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      birthTime: clearBirthTime ? null : (birthTime ?? this.birthTime),
      birthTimeKnown: birthTimeKnown ?? this.birthTimeKnown,
      latitude: clearCoords ? null : (latitude ?? this.latitude),
      longitude: clearCoords ? null : (longitude ?? this.longitude),
      birthPlaceId:
          clearBirthPlaceId ? null : (birthPlaceId ?? this.birthPlaceId),
      timezoneId: clearTimezoneId ? null : (timezoneId ?? this.timezoneId),
      timezoneResolutionStatus:
          timezoneResolutionStatus ?? this.timezoneResolutionStatus,
      birthPlaceUnknownConfirmed:
          birthPlaceUnknownConfirmed ?? this.birthPlaceUnknownConfirmed,
    );
  }
}
