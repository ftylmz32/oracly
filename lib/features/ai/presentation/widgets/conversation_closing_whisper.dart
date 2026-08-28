/// RC-002 — Gentle conversation ending — permission to leave.

library;



import 'package:flutter/material.dart';



import '../../../../core/copy/conversation_copy.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/reading_typography.dart';



class ConversationClosingWhisper extends StatelessWidget {

  const ConversationClosingWhisper({super.key});



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: EdgeInsets.fromLTRB(

        AppSpacing.xl,

        AppSpacing.lg,

        AppSpacing.xl,

        AppSpacing.md,

      ),

      child: Text(

        ConversationCopy.closingWhisper(),

        textAlign: TextAlign.center,

        style: ReadingTypography.closing(),

      ),

    );

  }

}

