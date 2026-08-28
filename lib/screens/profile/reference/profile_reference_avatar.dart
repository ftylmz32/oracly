/// Cosmic monogram or a real photo — gold ring, no invented face.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/oracly_chrome.dart';
import 'profile_avatar_geometry.dart';
import 'profile_avatar_letter.dart';
import 'profile_avatar_nebula.dart';
import 'profile_avatar_seed.dart';
import 'profile_avatar_sparkles.dart';
import 'profile_reference_tokens.dart';

class ProfileReferenceAvatar extends StatelessWidget {
  const ProfileReferenceAvatar({
    super.key,
    required this.initials,
    this.identity,
    this.photo,
    this.size,
  });

  /// First initial shown in the emblem.
  final String initials;

  /// Stable seed source (display name). Falls back to [initials].
  final String? identity;
  final ImageProvider? photo;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final box = size ?? ProfileReferenceTokens.avatarSize;
    final monogram = initials.trim().isEmpty ? 'Y' : initials.trim();
    final source = (identity ?? monogram).trim();
    final seed = ProfileAvatarSeed.of(source.isEmpty ? monogram : source);
    return SizedBox(
      width: box,
      height: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: OraclyChrome.gold.withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: OraclyChrome.violet.withValues(alpha: 0.22),
              blurRadius: 18,
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: OraclyChrome.goldMuted.withValues(alpha: 0.88),
              width: ProfileReferenceTokens.avatarBorderWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: OraclyChrome.goldHighlight.withValues(alpha: 0.55),
                  width: 0.7,
                ),
              ),
              child: ClipOval(
                child: photo != null
                    ? Image(
                        image: photo!,
                        fit: BoxFit.cover,
                        width: box,
                        height: box,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) => _Emblem(
                          monogram: monogram,
                          seed: seed,
                          letterSize: box * 0.35,
                        ),
                      )
                    : _Emblem(
                        monogram: monogram,
                        seed: seed,
                        letterSize: box * 0.35,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({
    required this.monogram,
    required this.seed,
    required this.letterSize,
  });

  final String monogram;
  final int seed;
  final double letterSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ProfileAvatarNebula(seed: seed),
        ProfileAvatarGeometry(seed: seed),
        ProfileAvatarSparkleLayer(seed: seed),
        Center(
          child: Text(
            ProfileAvatarLetter.of(monogram),
            style: AppTypography.headingL.copyWith(
              fontSize: letterSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: OraclyChrome.goldHighlight.withValues(alpha: 0.94),
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
