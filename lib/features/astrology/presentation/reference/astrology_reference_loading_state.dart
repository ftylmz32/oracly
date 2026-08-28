/// Loading state for Astrology — celestial aura, honest slow recovery.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/loading_cinema/loading_stage_astrology_aura.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_cinema.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../content/astrology/models/astrology_content.dart';
import '../../copy/astrology_presentation_copy.dart';
import 'astrology_hub_wheel.dart';
import 'astrology_reference_tokens.dart';

class AstrologyReferenceLoadingState extends StatelessWidget {
  const AstrologyReferenceLoadingState({
    super.key,
    required this.sign,
    this.viewportHeight,
    this.onRetry,
  });

  final ZodiacSignContent sign;
  final double? viewportHeight;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final layout = AstrologyReferenceTokens.layoutFor(viewportHeight);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          layout.heroHeight,
          constraints.maxWidth.isFinite ? constraints.maxWidth * 0.92 : 320.0,
        ).toDouble();

        return OraclyLoadingCinema(
          kind: OraclyLoadingKind.astrology,
          message: AstrologyPresentationCopy.loadingSky,
          onRetry: onRetry,
          stage: LoadingStageAstrologyAura(
            child: AstrologyHubWheel(sign: sign, side: side),
          ),
        );
      },
    );
  }
}
