/// Capture intake — pick photo, then soft quality tip (never cup ML).
library;

import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';
import 'coffee_image_input_port.dart';
import 'coffee_image_pick_exception.dart';
import 'coffee_image_validator.dart';

class CoffeeImageIntakeResult {
  const CoffeeImageIntakeResult({
    this.image,
    this.error,
    this.qualityHint,
  });

  final CoffeeImagePick? image;
  final String? error;
  final String? qualityHint;
}

abstract final class CoffeeImageIntake {
  CoffeeImageIntake._();

  static Future<CoffeeImageIntakeResult> fromCamera(
    CoffeeImageInputPort images,
  ) async {
    if (!images.cameraAvailable) {
      return CoffeeImageIntakeResult(error: CoffeeCopy.cameraUnavailable);
    }
    try {
      final picked = await images.pickFromCamera();
      if (picked == null) return const CoffeeImageIntakeResult();
      return assess(picked);
    } on CoffeeImagePickException catch (e) {
      return CoffeeImageIntakeResult(error: e.message);
    }
  }

  static Future<CoffeeImageIntakeResult> fromGallery(
    CoffeeImageInputPort images,
  ) async {
    if (!images.galleryAvailable) {
      return CoffeeImageIntakeResult(error: CoffeeCopy.galleryUnavailable);
    }
    try {
      final picked = await images.pickFromGallery();
      if (picked == null) return const CoffeeImageIntakeResult();
      return assess(picked);
    } on CoffeeImagePickException catch (e) {
      return CoffeeImageIntakeResult(error: e.message);
    }
  }

  static Future<CoffeeImageIntakeResult> assess(CoffeeImagePick picked) async {
    final check = await CoffeeImageValidator.validate(picked.path);
    if (!check.ok) {
      return CoffeeImageIntakeResult(image: picked, error: check.message);
    }
    return CoffeeImageIntakeResult(
      image: picked,
      qualityHint: check.guidance,
    );
  }
}
