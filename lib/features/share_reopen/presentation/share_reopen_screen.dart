/// Public-safe share reopen — highlight only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/oracly_header_action.dart';
import '../../../core/providers/backend_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_button.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../copy/share_reopen_copy.dart';
import '../models/share_access.dart';
import '../providers/share_reopen_providers.dart';
import '../services/share_access_resolver.dart';
import '../services/share_feature_open.dart';

class ShareReopenScreen extends ConsumerWidget {
  const ShareReopenScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ShareAccessResolver.resolve(
      uri,
      store: ref.watch(shareOwnershipStoreProvider),
      session: ref.watch(sessionManagerProvider).currentSession,
    );
    return OraclyScaffold(
      usePremiumBackground: true,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OraclyHeaderAction(
                  icon: AppIcons.back,
                  label: 'Geri',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                ShareReopenCopy.title,
                style: ReadingTypography.sectionLabel(),
              ),
              SizedBox(height: AppSpacing.md),
              if (access == null)
                Text(ShareReopenCopy.missing, style: ReadingTypography.body())
              else
                _ShareReopenBody(access: access),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareReopenBody extends StatelessWidget {
  const _ShareReopenBody({required this.access});

  final ShareAccess access;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ShareReopenCopy.typeLabel(access.payload.kind),
          style: ReadingTypography.opening(),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(access.payload.highlight, style: ReadingTypography.reflection()),
        SizedBox(height: AppSpacing.md),
        Text(ShareReopenCopy.footnote, style: ReadingTypography.footnote()),
        SizedBox(height: AppSpacing.xl),
        OraclyButton(
          text: ShareReopenCopy.openFeature,
          isExpanded: true,
          onPressed: () => ShareFeatureOpen.openPublic(
            context,
            access.payload.kind,
          ),
        ),
        if (access.isOwner) ...[
          SizedBox(height: AppSpacing.sm),
          OraclyButton(
            text: ShareReopenCopy.openMine,
            type: OraclyButtonType.ghost,
            isExpanded: true,
            onPressed: () => ShareFeatureOpen.openAuthorized(
              context,
              access.payload.kind,
            ),
          ),
        ],
        if (access.offerSignIn) ...[
          SizedBox(height: AppSpacing.sm),
          OraclyButton(
            text: ShareReopenCopy.signIn,
            type: OraclyButtonType.ghost,
            isExpanded: true,
            onPressed: () => ShareFeatureOpen.openSignIn(context),
          ),
        ],
      ],
    );
  }
}
