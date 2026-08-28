/// Camera, gallery, or remove — local files only, never uploaded to AI.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/providers/app_providers.dart';
import '../../settings/reference/settings_choice_sheet.dart';
import '../copy/profile_copy.dart';
import 'profile_photo_store.dart';

enum ProfilePhotoAction { camera, gallery, remove, none }

abstract final class ProfilePhotoActions {
  ProfilePhotoActions._();

  static bool get cameraAvailable =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;

  static Future<ProfilePhotoAction?> choose(
    BuildContext context, {
    required bool hasPhoto,
  }) {
    return showSettingsChoiceSheet<ProfilePhotoAction>(
      context: context,
      title: ProfileCopy.photoTitle,
      current: ProfilePhotoAction.none,
      options: [
        if (cameraAvailable)
          (ProfilePhotoAction.camera, ProfileCopy.photoCamera),
        (ProfilePhotoAction.gallery, ProfileCopy.photoGallery),
        if (hasPhoto) (ProfilePhotoAction.remove, ProfileCopy.photoRemove),
      ],
    );
  }

  static Future<bool?> commit(WidgetRef ref, ProfilePhotoAction action) async {
    if (action == ProfilePhotoAction.remove) {
      await ProfilePhotoStore.clear(ref.read(localStorageProvider));
      ref.read(profilePhotoEpochProvider.notifier).state++;
      return true;
    }
    if (action == ProfilePhotoAction.camera) {
      return _pick(ref, ImageSource.camera);
    }
    if (action == ProfilePhotoAction.gallery) {
      return _pick(ref, ImageSource.gallery);
    }
    return null;
  }

  static Future<bool?> _pick(WidgetRef ref, ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        if (!cameraAvailable) return false;
        final status = await Permission.camera.request();
        if (!status.isGranted) return false;
      }
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 88,
      );
      if (file == null) return null;
      await ProfilePhotoStore.save(ref.read(localStorageProvider), file.path);
      ref.read(profilePhotoEpochProvider.notifier).state++;
      return true;
    } catch (_) {
      return false;
    }
  }
}
