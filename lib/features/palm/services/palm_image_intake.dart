/// Capture intake — pick, normalize to JPEG, then soft quality tip.
library;

import '../../coffee/models/coffee_image_pick.dart';
import '../../coffee/services/coffee_image_input_port.dart';
import '../../coffee/services/coffee_image_pick_exception.dart';
import '../copy/palm_copy.dart';
import 'palm_image_normalizer.dart';
import 'palm_image_validator.dart';

class PalmImageIntakeResult {
  const PalmImageIntakeResult({
    this.image,
    this.error,
    this.qualityHint,
  });

  final CoffeeImagePick? image;
  final String? error;
  final String? qualityHint;
}

abstract final class PalmImageIntake {
  PalmImageIntake._();

  static Future<PalmImageIntakeResult> fromCamera(
    CoffeeImageInputPort images,
  ) async {
    if (!images.cameraAvailable) {
      return PalmImageIntakeResult(error: PalmCopy.cameraUnavailable);
    }
    try {
      final picked = await images.pickFromCamera();
      if (picked == null) return const PalmImageIntakeResult();
      return assess(picked);
    } on CoffeeImagePickException catch (e) {
      return PalmImageIntakeResult(error: e.message);
    }
  }

  static Future<PalmImageIntakeResult> fromGallery(
    CoffeeImageInputPort images,
  ) async {
    if (!images.galleryAvailable) {
      return PalmImageIntakeResult(error: PalmCopy.galleryUnavailable);
    }
    try {
      final picked = await images.pickFromGallery();
      if (picked == null) return const PalmImageIntakeResult();
      return assess(picked);
    } on CoffeeImagePickException catch (e) {
      return PalmImageIntakeResult(error: e.message);
    }
  }

  static Future<PalmImageIntakeResult> assess(CoffeeImagePick picked) async {
    late final CoffeeImagePick normalized;
    try {
      normalized = await PalmImageNormalizer.normalize(picked);
    } on PalmNormalizeException catch (e) {
      return PalmImageIntakeResult(error: e.message);
    }
    final check = await PalmImageValidator.validate(normalized.path);
    if (!check.ok) {
      return PalmImageIntakeResult(image: normalized, error: check.message);
    }
    return PalmImageIntakeResult(
      image: normalized,
      qualityHint: check.guidance,
    );
  }
}
