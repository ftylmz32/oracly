/// Port for soul-mate illustration — no fake images.
library;

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
  });

  const SoulMateDrawResult.unavailable(String message)
      : this._(available: false, message: message);

  const SoulMateDrawResult.success({required List<int> imageBytes})
      : this._(available: true, imageBytes: imageBytes);

  final bool available;
  final String? message;
  final List<int>? imageBytes;

  bool get hasPortrait =>
      available && imageBytes != null && imageBytes!.isNotEmpty;
}

abstract class SoulMateDrawPort {
  bool get isAvailable;
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request);
}
