/// Visual frame — personality scope around the existing OR chat shell.
library;

import 'package:flutter/material.dart';

import '../../../premium/models/personalization_models.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import 'companion_or_presence.dart';
import 'companion_or_visual.dart';
import 'companion_reference_atmosphere.dart';

class CompanionOrChatFrame extends StatelessWidget {
  const CompanionOrChatFrame({
    super.key,
    required this.personality,
    required this.presence,
    required this.child,
  });

  final AiPersonality personality;
  final CompanionOrPresence presence;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CompanionOrVisual(
      personality: personality,
      presence: presence,
      child: OraclyScaffold(
        safeArea: false,
        backgroundOverlay: const CompanionReferenceAtmosphere(
          child: SizedBox.shrink(),
        ),
        child: child,
      ),
    );
  }
}
