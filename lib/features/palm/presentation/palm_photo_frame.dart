/// Shared gold frame for palm photos — landing, capture, wait, result.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'palm_tokens.dart';

class PalmPhotoFrame extends StatelessWidget {
  const PalmPhotoFrame({
    super.key,
    required this.child,
    this.hero = false,
    this.attention = false,
  });

  final Widget child;
  final bool hero;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final goldA = attention ? 0.40 : (hero ? 0.30 : 0.26);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: PalmTokens.heroRadius,
        boxShadow: PalmTokens.frameShadows(hero: hero),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: PalmTokens.heroRadius,
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: goldA),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: PalmTokens.heroRadius,
          child: child,
        ),
      ),
    );
  }
}
