/// Profile loaded body — SafeArea + scroll; nav never covers CTAs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/user_profile.dart';
import '../../../core/experience/providers/continue_where_you_left_off_provider.dart';
import '../../../features/personal_discovery/providers/personal_discovery_providers.dart';
import '../../../shared/widgets/oracly_button.dart';
import '../copy/profile_copy.dart';
import 'profile_reference_app_bar.dart';
import 'profile_reference_header.dart';
import 'profile_reference_scroll_stack.dart';
import 'profile_reference_tokens.dart';

class ProfileReferenceBody extends ConsumerWidget {
  const ProfileReferenceBody({
    super.key,
    required this.profile,
    required this.onBack,
    required this.onEditName,
    this.onPhotoTap,
    this.onPhotoRemove,
    this.onLogout,
    this.photo,
  });

  final UserProfileModel profile;
  final VoidCallback onBack;
  final VoidCallback onEditName;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onPhotoRemove;
  final VoidCallback? onLogout;
  final ImageProvider? photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(personalDiscoveryProfileProvider);
    final hasHistory = discoveryAsync.valueOrNull?.hasHistory ?? false;
    final resumeTarget = ref.watch(continueWhereYouLeftOffProvider).valueOrNull;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              ProfileReferenceTokens.screenHorizontal,
              ProfileReferenceTokens.screenTop,
              ProfileReferenceTokens.screenHorizontal,
              0,
            ),
            child: ProfileReferenceAppBar(onBack: onBack),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.fromLTRB(
                    ProfileReferenceTokens.screenHorizontal,
                    ProfileReferenceTokens.headerToHero,
                    ProfileReferenceTokens.screenHorizontal,
                    ProfileReferenceTokens.scrollBottomInset(context),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileReferenceHeader(
                          name: profile.name,
                          photo: photo,
                          onAvatarTap: onEditName,
                          onPhotoTap: onPhotoTap,
                          onPhotoRemove: onPhotoRemove,
                        ),
                        SizedBox(height: ProfileReferenceTokens.afterHero),
                        ProfileReferenceScrollStack(
                          hasHistory: hasHistory,
                          discoveryLoading: discoveryAsync.isLoading,
                          resumeTarget: resumeTarget,
                        ),
                        if (onLogout != null) ...[
                          SizedBox(height: ProfileReferenceTokens.afterPremium),
                          OraclyButton(
                            text: ProfileCopy.logoutTitle,
                            onPressed: onLogout,
                            type: OraclyButtonType.danger,
                            size: OraclyButtonSize.large,
                            enabled: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
