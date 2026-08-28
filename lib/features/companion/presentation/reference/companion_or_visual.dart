/// Inherited OR visual — personality + presence for the current chat.
library;

import 'package:flutter/material.dart';

import '../../../premium/models/personalization_models.dart';
import 'companion_or_atmosphere.dart';
import 'companion_or_presence.dart';

class CompanionOrVisual extends InheritedWidget {
  const CompanionOrVisual({
    super.key,
    required this.personality,
    required this.presence,
    required super.child,
  });

  final AiPersonality personality;
  final CompanionOrPresence presence;

  CompanionOrAtmosphere get atmosphere =>
      CompanionOrAtmosphere.of(personality, presence);

  static CompanionOrVisual? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CompanionOrVisual>();
  }

  static AiPersonality personalityOf(BuildContext context) =>
      maybeOf(context)?.personality ?? AiPersonality.mystical;

  static CompanionOrPresence presenceOf(BuildContext context) =>
      maybeOf(context)?.presence ?? CompanionOrPresence.idle;

  static CompanionOrAtmosphere atmosphereOf(BuildContext context) {
    return maybeOf(context)?.atmosphere ??
        CompanionOrAtmosphere.of(
          AiPersonality.mystical,
          CompanionOrPresence.idle,
        );
  }

  @override
  bool updateShouldNotify(CompanionOrVisual oldWidget) {
    return personality != oldWidget.personality ||
        presence != oldWidget.presence;
  }
}
