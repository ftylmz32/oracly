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
  });

  final int updatedAtMillis;
  final String? name;
  final DateTime? birthDate;
  final String? birthPlaceTr;
  final String language;
  final AiPersonality style;

  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);

  Map<String, dynamic> toJson() => {
    'updatedAtMillis': updatedAtMillis,
    if (name != null) 'name': name,
    if (birthDate != null) 'birthDateIso': birthDate!.toIso8601String(),
    if (birthPlaceTr != null) 'birthPlaceTr': birthPlaceTr,
    'language': language,
    'style': style.name,
  };

  factory OnboardingSetupDraft.fromJson(Map<String, dynamic> json) {
    final updatedAtMillis = json['updatedAtMillis'] as int? ?? 0;
    return OnboardingSetupDraft(
      updatedAtMillis: updatedAtMillis,
      name: json['name'] as String?,
      birthDate: (json['birthDateIso'] as String?)?.isNotEmpty == true
          ? DateTime.tryParse(json['birthDateIso'] as String)
          : null,
      birthPlaceTr: json['birthPlaceTr'] as String?,
      language: (json['language'] as String?) ?? 'tr',
      style: AiPersonality.values.byName(
        json['style'] as String? ?? 'mystical',
      ),
    );
  }
}
