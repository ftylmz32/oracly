/// OR-1190 — Navigation helpers for oracle conversation.
library;

import 'package:flutter/material.dart';

import '../models/oracle_reading_context.dart';
import '../../presentation/screens/oracle_conversation_screen.dart';

PageRoute<T> oracleConversationRoute<T>({
  required OracleReadingContext readingContext,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) {
      return OracleConversationScreen(readingContext: readingContext);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

void openOracleConversation(
  BuildContext context, {
  required OracleReadingContext readingContext,
}) {
  Navigator.of(context).push(
    oracleConversationRoute(readingContext: readingContext),
  );
}
