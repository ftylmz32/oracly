/// Persisted Soulmate flagship result — one canonical latest record.
library;

import '../data/soul_mate_interpretation_catalogue.dart';
import '../services/soul_mate_draw_port.dart';
import '../services/soul_mate_identity.dart';

class SoulMateSavedResult {
  const SoulMateSavedResult({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.birthDate,
    required this.portraitPath,
    required this.parts,
    this.gender,
    this.intention,
    this.localeCode = 'tr',
    this.identity,
  });

  final String id;
  final DateTime createdAt;
  final String name;
  final DateTime birthDate;
  final SoulMateGenderPref? gender;
  final String? intention;
  final String portraitPath;
  final SoulMateReadingParts parts;
  final String localeCode;
  final SoulMateIdentity? identity;

  bool get hasAuthoritativeInterpretation => parts.authoritative;

  SoulMateDrawRequest toRequest() => SoulMateDrawRequest(
        name: name,
        birthDate: birthDate,
        gender: gender,
        intention: intention,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        if (gender != null) 'gender': gender!.name,
        if (intention != null && intention!.isNotEmpty) 'intention': intention,
        'portraitPath': portraitPath,
        'localeCode': localeCode,
        'parts': {
          'energy': parts.energy,
          'attraction': parts.attraction,
          'dynamics': parts.dynamics,
          'feeling': parts.feeling,
          'yourSide': parts.yourSide,
          'meeting': parts.meeting,
          'authoritative': parts.authoritative,
        },
        if (identity != null) 'identity': identity!.toJson(),
      };

  factory SoulMateSavedResult.fromJson(Map<String, dynamic> json) {
    final parts = json['parts'];
    return SoulMateSavedResult(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      gender: _genderOf(json['gender'] as String?),
      intention: json['intention'] as String?,
      portraitPath: json['portraitPath'] as String,
      localeCode: json['localeCode'] as String? ?? 'tr',
      parts: SoulMateReadingParts(
        energy: (parts['energy'] as String?) ?? '',
        attraction: (parts['attraction'] as String?) ?? '',
        dynamics: (parts['dynamics'] as String?) ?? '',
        feeling: (parts['feeling'] as String?) ?? '',
        yourSide: (parts['yourSide'] as String?) ?? '',
        meeting: (parts['meeting'] as String?) ?? '',
        authoritative: parts['authoritative'] == true,
      ),
      identity: SoulMateIdentity.fromMap(json['identity']),
    );
  }

  static SoulMateGenderPref? _genderOf(String? raw) => switch (raw) {
        'feminine' => SoulMateGenderPref.feminine,
        'masculine' => SoulMateGenderPref.masculine,
        _ => null,
      };
}