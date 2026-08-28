/// Reference-accurate Profile screen — visual shell, honest session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/auth_copy.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../features/premium/providers/premium_providers.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../../../shared/ui/oracly_dialog.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../shared/widgets/oracly_error_state.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../../../shared/widgets/oracly_skeleton_loader.dart';
import '../copy/profile_copy.dart';
import '../data/profile_photo_actions.dart';
import '../data/profile_photo_store.dart';
import 'profile_account_session.dart';
import 'profile_reference_atmosphere.dart';
import 'profile_reference_body.dart';

/// Profile tab — reference UI only.
class ProfileReferenceScreen extends ConsumerWidget {
  const ProfileReferenceScreen({super.key});

  Future<void> _editName(
    WidgetRef ref,
    BuildContext context,
    String current,
  ) async {
    final name = await OraclyDialog.prompt(
      context,
      title: ProfileCopy.nameTitle,
      hint: ProfileCopy.nameHint,
      initial: current,
      confirmLabel: ProfileCopy.saveLabel,
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(userProfileProvider.notifier).saveName(name.trim());
    }
  }

  Future<void> _editPhoto(WidgetRef ref, BuildContext context) async {
    final action = await ProfilePhotoActions.choose(
      context,
      hasPhoto: ref.read(profilePhotoProvider) != null,
    );
    if (action == null) return;
    final ok = await ProfilePhotoActions.commit(ref, action);
    if (ok == false && context.mounted) {
      OraclySnackBar.show(
        context,
        message: action == ProfilePhotoAction.camera
            ? ProfileCopy.photoCameraUnavailable
            : ProfileCopy.photoUnavailable,
      );
    }
  }

  Future<void> _removePhoto(WidgetRef ref, BuildContext context) async {
    final ok = await ProfilePhotoActions.commit(
      ref,
      ProfilePhotoAction.remove,
    );
    if (ok != true && context.mounted) {
      OraclySnackBar.show(
        context,
        message: ProfileCopy.photoUnavailable,
      );
    }
  }

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  Future<void> _logout(WidgetRef ref, BuildContext context) async {
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    OraclySnackBar.show(context, message: AuthCopy.signedOut);
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final premium = ref.watch(premiumStatusProvider).isPremium;
    final photo = ref.watch(profilePhotoProvider);
    final canLogout = profileHasRealAccountSession(
      auth: ref.watch(authServiceProvider),
      session: ref.watch(sessionManagerProvider).currentSession,
    );

    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const ProfileReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: profileAsync.when(
        loading: () =>
            OraclySkeletonLoader(message: ResilienceCopy.profileLoading),
        error: (e, _) => OraclyErrorState(
          title: ResilienceCopy.errorTitle,
          message: ResilienceCopy.profileLoadFailed,
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (UserProfileModel profile) {
          return ProfileReferenceBody(
            profile: profile.copyWith(isPremium: premium),
            photo: photo,
            onBack: () => _onBack(context),
            onEditName: () => _editName(ref, context, profile.name),
            onPhotoTap: () => _editPhoto(ref, context),
            onPhotoRemove: () => _removePhoto(ref, context),
            onLogout: canLogout ? () => _logout(ref, context) : null,
          );
        },
      ),
    );
  }
}
