/// SPRINT-002 — Birth profile from onboarding.
library;

class BirthProfile {
  const BirthProfile({
    required this.birthDate,
    required this.birthPlace,
    this.birthTime,
    this.birthTimeKnown = false,
    this.latitude,
    this.longitude,
  });

  final DateTime birthDate;
  final String birthPlace;
  final DateTime? birthTime;
  final bool birthTimeKnown;
  final double? latitude;
  final double? longitude;

  bool get hasKnownTime => birthTimeKnown && birthTime != null;

  Map<String, dynamic> toJson() => {
        'birthDate': birthDate.toIso8601String(),
        'birthPlace': birthPlace,
        if (birthTime != null) 'birthTime': birthTime!.toIso8601String(),
        'birthTimeKnown': birthTimeKnown,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  factory BirthProfile.fromJson(Map<String, dynamic> json) {
    return BirthProfile(
      birthDate: DateTime.parse(json['birthDate'] as String),
      birthPlace: json['birthPlace'] as String,
      birthTime: json['birthTime'] != null
          ? DateTime.parse(json['birthTime'] as String)
          : null,
      birthTimeKnown: json['birthTimeKnown'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
