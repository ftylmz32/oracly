/// Port for soul-mate illustration — no fake images.
library;

import '../../ai/production/ai_failure.dart';
import 'soul_mate_generation_policy.dart';
import 'soul_mate_identity.dart';

enum SoulMateGenderPref { feminine, masculine }

class SoulMateDrawRequest {
  const SoulMateDrawRequest({
    required this.name,
    required this.birthDate,
    this.gender,
    this.intention,
  });

  final String name;
  final DateTime birthDate;
  final SoulMateGenderPref? gender;
  final String? intention;
}

class SoulMateDrawResult {
  const SoulMateDrawResult._({
    required this.available,
    this.message,
    this.imageBytes,
    this.failureKind,
    this.aiKind,
    this.operationId,
    this.declined = false,
    this.identity,
  });

  const SoulMateDrawResult.unavailable(
    String message, {
    SoulMateFailureKind failureKind = SoulMateFailureKind.temporary,
    AiFailureKind? aiKind,
  }) : this._(
          available: false,
          message: message,
          failureKind: failureKind,
          aiKind: aiKind,
        );

  const SoulMateDrawResult.declined()
      : this._(available: false, declined: true);

  const SoulMateDrawResult.success({
    required List<int> imageBytes,
    SoulMateIdentity? identity,
  }) : this._(available: true, imageBytes: imageBytes, identity: identity);

  final bool available;
  final String? message;
  final List<int>? imageBytes;
  final SoulMateFailureKind? failureKind;
  final AiFailureKind? aiKind;
  final String? operationId;
  final bool declined;
  final SoulMateIdentity? identity;

  bool get hasPortrait =>
      available && imageBytes != null && imageBytes!.isNotEmpty;

  SoulMateDrawResult tagged(String operationId, {SoulMateFailureKind? failureKind}) {
    return SoulMateDrawResult._(
      available: available,
      message: message,
      imageBytes: imageBytes,
      failureKind: failureKind ?? this.failureKind,
      aiKind: aiKind,
      operationId: operationId,
      declined: declined,
      identity: identity,
    );
  }
}

abstract class SoulMateDrawPort {
  bool get isAvailable;
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request);
}
