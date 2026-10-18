library;

import '../../premium/models/personalization_models.dart';

/// Persisted draft for optional onboarding profile setup.
///
/// This exists only so we can resume safely after app close/kill.
class OnboardingSetupDraft {
  const OnboardingSetupDraft({
    required this.updatedAtMillis,
    this.name,
    this.birthDate,
    this.birthPlaceTr,
    required this.language,
    required this.style,
    this.scene = 0,
    this.interests = const [],
    this.birthTimeKnown = false,
    this.birthHour,
    this.birthMinute,
  });

  final int updatedAtMillis;
  final String? name;
  final DateTime? birthDate;
  final String? birthPlaceTr;
  final String language;
  final AiPersonality style;

  /// 0 gate · 1 name · 2 interests · 3 sky · 4 welcome.
  final int scene;
  final List<String> interests;

  /// Explicit. Unknown time never becomes a guessed hour.
  final bool birthTimeKnown;
  final int? birthHour;
  final int? birthMinute;

  DateTime? get birthTime {
    if (!birthTimeKnown || birthHour == null || birthMinute == null) {
      return null;
    }
    final date = birthDate ?? DateTime(2000);
    return DateTime(date.year, date.month, date.day, birthHour!, birthMinute!);
  }

  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);

  Map<String, dynamic> toJson() => {
    'updatedAtMillis': updatedAtMillis,
    if (name != null) 'name': name,
    if (birthDate != null) 'birthDateIso': birthDate!.toIso8601String(),
    if (birthPlaceTr != null) 'birthPlaceTr': birthPlaceTr,
    'language': language,
    'style': style.name,
    'scene': scene,
    if (interests.isNotEmpty) 'interests': interests,
    'birthTimeKnown': birthTimeKnown,
    if (birthHour != null) 'birthHour': birthHour,
    if (birthMinute != null) 'birthMinute': birthMinute,
  };

  OnboardingSetupDraft copy({
    String? name,
    DateTime? birthDate,
    String? birthPlaceTr,
    int? scene,
    List<String>? interests,
    bool? birthTimeKnown,
    int? birthHour,
    int? birthMinute,
    bool setName = false,
    bool setBirthDate = false,
    bool setPlace = false,
    bool setTime = false,
  }) {
    return OnboardingSetupDraft(
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      name: setName ? name : this.name,
      birthDate: setBirthDate ? birthDate : this.birthDate,
      birthPlaceTr: setPlace ? birthPlaceTr : this.birthPlaceTr,
      language: language,
      style: style,
      scene: scene ?? this.scene,
      interests: interests ?? this.interests,
      birthTimeKnown: birthTimeKnown ?? this.birthTimeKnown,
      birthHour: setTime ? birthHour : this.birthHour,
      birthMinute: setTime ? birthMinute : this.birthMinute,
    );
  }

  factory OnboardingSetupDraft.fromJson(Map<String, dynamic> json) {
    final updatedAtMillis = json['updatedAtMillis'] as int? ?? 0;
    final name = json['name'] as String?;
    final interests = (json['interests'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final storedScene = json['scene'] as int?;
    final scene = storedScene ?? (name != null && name.trim().isNotEmpty ? 1 : 0);
    return OnboardingSetupDraft(
      updatedAtMillis: updatedAtMillis,
      name: name,
      birthDate: (json['birthDateIso'] as String?)?.isNotEmpty == true
          ? DateTime.tryParse(json['birthDateIso'] as String)
          : null,
      birthPlaceTr: json['birthPlaceTr'] as String?,
      language: (json['language'] as String?) ?? 'tr',
      style: AiPersonality.values.byName(
        json['style'] as String? ?? 'mystical',
      ),
      scene: scene.clamp(0, 4),
      interests: interests,
      birthTimeKnown: json['birthTimeKnown'] as bool? ?? false,
      birthHour: json['birthHour'] as int?,
      birthMinute: json['birthMinute'] as int?,
    );
  }
}
