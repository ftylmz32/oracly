/// Reference-accurate Profile screen — visual shell, honest session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
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
import 'profile_sign_out.dart';

class ProfileReferenceScreen extends ConsumerStatefulWidget {
  const ProfileReferenceScreen({super.key});

  @override
  ConsumerState<ProfileReferenceScreen> createState() =>
      _ProfileReferenceScreenState();
}

class _ProfileReferenceScreenState
    extends ConsumerState<ProfileReferenceScreen> {
  bool _loggingOut = false;

  Future<void> _editName(BuildContext context, String current) async {
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

  Future<void> _editPhoto(BuildContext context) async {
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

  Future<void> _removePhoto(BuildContext context) async {
    final ok = await ProfilePhotoActions.commit(ref, ProfilePhotoAction.remove);
    if (ok != true && context.mounted) {
      OraclySnackBar.show(context, message: ProfileCopy.photoUnavailable);
    }
  }

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  Future<void> _logout(BuildContext context) async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    final ok = await profileSignOut(ref: ref, context: context);
    if (!mounted) return;
    if (!ok) setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final premium = ref.watch(premiumStatusProvider).isPremium;
    final photo = ref.watch(profilePhotoProvider);
    final canLogout =
        !_loggingOut &&
        profileHasRealAccountSession(
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
        loading: () => SafeArea(
          child: OraclySkeletonLoader(message: ResilienceCopy.profileLoading),
        ),
        error: (e, _) => SafeArea(
          child: OraclyErrorState(
            title: ResilienceCopy.errorTitle,
            message: ResilienceCopy.profileLoadFailed,
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
        data: (UserProfileModel profile) {
          return ProfileReferenceBody(
            profile: profile.copyWith(isPremium: premium),
            photo: photo,
            onBack: () => _onBack(context),
            onEditName: () => _editName(context, profile.name),
            onPhotoTap: () => _editPhoto(context),
            onPhotoRemove: () => _removePhoto(context),
            onLogout: canLogout ? () => _logout(context) : null,
          );
        },
      ),
    );
  }
}
