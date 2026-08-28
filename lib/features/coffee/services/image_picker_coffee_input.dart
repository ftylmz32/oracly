/// image_picker-backed coffee photo input.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';
import 'coffee_image_input_port.dart';
import 'coffee_image_pick_exception.dart';

class ImagePickerCoffeeInput implements CoffeeImageInputPort {
  ImagePickerCoffeeInput({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  bool get cameraAvailable =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;

  @override
  bool get galleryAvailable => true;

  @override
  Future<CoffeeImagePick?> pickFromCamera() async {
    if (!cameraAvailable) {
      throw CoffeeImagePickException(CoffeeCopy.cameraUnavailable);
    }
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          throw CoffeeImagePickException(
            CoffeeCopy.cameraPermissionPermanent,
          );
        }
        throw CoffeeImagePickException(CoffeeCopy.cameraPermissionDenied);
      }
    } on CoffeeImagePickException {
      rethrow;
    } catch (_) {
      throw CoffeeImagePickException(CoffeeCopy.cameraUnavailable);
    }
    return _pick(ImageSource.camera, CoffeeCopy.cameraUnavailable);
  }

  @override
  Future<CoffeeImagePick?> pickFromGallery() {
    return _pick(ImageSource.gallery, CoffeeCopy.galleryUnavailable);
  }

  Future<CoffeeImagePick?> _pick(ImageSource source, String failure) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );
      if (file == null) return null;
      return CoffeeImagePick(path: file.path, mimeType: file.mimeType);
    } on CoffeeImagePickException {
      rethrow;
    } on PlatformException {
      throw CoffeeImagePickException(failure);
    } catch (_) {
      throw CoffeeImagePickException(failure);
    }
  }
}
