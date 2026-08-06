/// EPIC-014 — Quiet footnote for AI interpretation surfaces.

library;



import 'package:flutter/material.dart';



import '../copy/transparency_copy.dart';

import '../theme/app_spacing.dart';

import '../theme/reading_typography.dart';



class TransparencyFootnote extends StatelessWidget {

  const TransparencyFootnote({

    super.key,

    this.text = TransparencyCopy.interpretationFootnote,

    this.alignment = TextAlign.center,

    this.padding,

  });



  final String text;

  final TextAlign alignment;

  final EdgeInsetsGeometry? padding;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: padding ??

          EdgeInsets.symmetric(

            horizontal: AppSpacing.md,

            vertical: AppSpacing.sm,

          ),

      child: Text(

        text,

        textAlign: alignment,

        style: ReadingTypography.footnote(),

      ),

    );

  }

}

