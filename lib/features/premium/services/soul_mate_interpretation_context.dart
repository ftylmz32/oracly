/// Real Soulmate facts only ? no invented city, job, or memory.
library;

import 'soul_mate_draw_port.dart';
import 'soul_mate_identity.dart';

class SoulMateInterpretationContext {
  const SoulMateInterpretationContext({
    required this.name,
    required this.birthDate,
    required this.ageYears,
    this.gender,
    this.intention,
    this.identity,
    this.memorySummary,
  });

  final String name;
  final String birthDate;
  final int? ageYears;
  final String? gender;
  final String? intention;
  final SoulMateIdentity? identity;
  final String? memorySummary;

  static SoulMateInterpretationContext fromRequest(
    SoulMateDrawRequest request, {
    SoulMateIdentity? identity,
    DateTime? now,
    String? memorySummary,
  }) {
    final birth = _iso(request.birthDate);
    return SoulMateInterpretationContext(
      name: request.name.trim(),
      birthDate: birth,
      ageYears: _age(request.birthDate, now ?? DateTime.now()),
      gender: request.gender?.name,
      intention: _clean(request.intention),
      identity: identity,
      memorySummary: _clean(memorySummary),
    );
  }

  String signature() {
    return [
      name.toLowerCase(),
      birthDate,
      gender ?? '',
      (intention ?? '').toLowerCase(),
      identity?.presence ?? '',
      identity?.mood ?? '',
      identity?.relationshipArchetype ?? '',
      identity?.stylingEnergy ?? '',
      identity?.nonce ?? '',
      memorySummary ?? '',
    ].join('|');
  }

  static String _iso(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static int? _age(DateTime birth, DateTime now) {
    var years = now.year - birth.year;
    final beforeBirthday =
        now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day);
    if (beforeBirthday) years -= 1;
    if (years < 18 || years > 120) return null;
    return years;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
