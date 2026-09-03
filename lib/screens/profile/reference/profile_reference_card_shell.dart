/// Shared glass card shell for reference profile widgets.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/oracly_glass_card.dart';
import 'profile_reference_tokens.dart';
import 'profile_surface_weight.dart';

class ProfileReferenceCardShell extends StatelessWidget {
  const ProfileReferenceCardShell({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.glowStrength,
    this.weight = ProfileSurfaceWeight.story,
  });

  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double? glowStrength;
  final ProfileSurfaceWeight weight;

  @override
  Widget build(BuildContext context) {
    final premium = weight == ProfileSurfaceWeight.hero;
    final elevated =
        weight == ProfileSurfaceWeight.highlight ||
        weight == ProfileSurfaceWeight.story;
    final glow =
        glowStrength ??
        switch (weight) {
          ProfileSurfaceWeight.hero => 1.22,
          ProfileSurfaceWeight.highlight => 1.05,
          ProfileSurfaceWeight.story => 0.78,
          ProfileSurfaceWeight.utility => 0.48,
        };
    final radius =
        borderRadius ??
        switch (weight) {
          ProfileSurfaceWeight.hero => ProfileReferenceTokens.heroRadius,
          ProfileSurfaceWeight.highlight => AppRadius.s24,
          ProfileSurfaceWeight.story => AppRadius.s24,
          ProfileSurfaceWeight.utility => AppRadius.s20,
        };
    final pad =
        padding ??
        switch (weight) {
          ProfileSurfaceWeight.hero => ProfileReferenceTokens.heroPadding,
          ProfileSurfaceWeight.highlight => const EdgeInsets.fromLTRB(
            14,
            12,
            12,
            12,
          ),
          ProfileSurfaceWeight.story => const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            14,
          ),
          ProfileSurfaceWeight.utility => const EdgeInsets.fromLTRB(
            14,
            10,
            12,
            10,
          ),
        };

    return OraclyGlassCard(
      height: height,
      width: width,
      padding: pad,
      borderRadius: radius,
      onTap: onTap,
      elevated: elevated,
      premium: premium,
      glowStrength: glow,
      child: child,
    );
  }
}
