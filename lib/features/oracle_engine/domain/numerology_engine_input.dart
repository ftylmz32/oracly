/// OR-1140 — Numerology engine input payload.
library;

class NumerologyEngineInput {
  const NumerologyEngineInput({
    required this.birthDate,
    this.fullName,
  });

  final DateTime birthDate;
  final String? fullName;
}

class NumerologyReading {
  const NumerologyReading({
    required this.id,
    required this.lifePathNumber,
    required this.nameNumber,
    required this.createdAt,
  });

  final String id;
  final int lifePathNumber;
  final int? nameNumber;
  final DateTime createdAt;

  Map<String, dynamic> toFacts() => {
        'id': id,
        'lifePathNumber': lifePathNumber,
        if (nameNumber != null) 'nameNumber': nameNumber,
      };
}
