/// Message surfaces — editorial OR, muted user notes.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceBubbleSurface extends StatelessWidget {
  const CompanionReferenceBubbleSurface({
    super.key,
    required this.child,
    required this.isUser,
  });

  final Widget child;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (isUser) return _UserNote(child: child);
    return _OrEditorial(child: child);
  }
}

class _UserNote extends StatelessWidget {
  const _UserNote({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: CompanionReferenceTokens.userRadius,
        color: const Color(0xFF120E16).withValues(alpha: 0.92),
        border: Border.all(
          color: OraclyChrome.violet.withValues(alpha: 0.16),
          width: 0.45,
        ),
      ),
      child: child,
    );
  }
}

class _OrEditorial extends StatelessWidget {
  const _OrEditorial({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: OraclyChrome.gold.withValues(alpha: 0.28),
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: child,
      ),
    );
  }
}
