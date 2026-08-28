/// Camera / gallery input for coffee-cup photos.
library;

import '../models/coffee_image_pick.dart';

abstract class CoffeeImageInputPort {
  const CoffeeImageInputPort();

  bool get cameraAvailable;
  bool get galleryAvailable;

  Future<CoffeeImagePick?> pickFromCamera();
  Future<CoffeeImagePick?> pickFromGallery();
}

class UnavailableCoffeeImageInput extends CoffeeImageInputPort {
  const UnavailableCoffeeImageInput();

  @override
  bool get cameraAvailable => false;

  @override
  bool get galleryAvailable => false;

  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;

  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}
