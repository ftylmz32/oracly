/// OR-1110 — Markdown-ready AI message body renderer.

library;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_radius.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../../../core/theme/craftsmanship_rhythm.dart';

import '../../../../core/theme/reading_typography.dart';

import '../../services/ai_formatter.dart';



/// Renders markdown blocks — ready for flutter_markdown swap-in.

class AIMarkdownBody extends StatelessWidget {

  const AIMarkdownBody({

    super.key,

    required this.markdown,

    this.textStyle,

  });



  final String markdown;

  final TextStyle? textStyle;



  @override

  Widget build(BuildContext context) {

    final blocks = AIFormatter.toBlocks(markdown);

    final base = textStyle ?? ReadingTypography.body();



    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: blocks.map((block) => _BlockWidget(block: block, base: base)).toList(),

    );

  }

}



class _BlockWidget extends StatelessWidget {

  const _BlockWidget({required this.block, required this.base});



  final FormattedBlock block;

  final TextStyle base;



  @override

  Widget build(BuildContext context) {

    return switch (block.type) {

      FormattedBlockType.heading => Padding(

          padding: EdgeInsets.only(

            top: AppSpacing.xs,

            bottom: CraftsmanshipRhythm.paragraphGap,

          ),

          child: Text(

            block.content,

            style: ReadingTypography.sectionLabel(fontSize: 13),

          ),

        ),

      FormattedBlockType.code => Padding(

          padding: EdgeInsets.only(bottom: CraftsmanshipRhythm.paragraphGap),

          child: _CodeBlock(code: block.content, language: block.language),

        ),

      FormattedBlockType.quote => Padding(

          padding: EdgeInsets.only(bottom: CraftsmanshipRhythm.paragraphGap),

          child: Container(

            padding: EdgeInsets.all(AppSpacing.sm),

            decoration: BoxDecoration(

              border: Border(

                left: BorderSide(color: AppColors.gold, width: 2),

              ),

            ),

            child: Text(

              block.content,

              style: ReadingTypography.reflection(color: AppColors.textHint),

            ),

          ),

        ),

      FormattedBlockType.listItem => Padding(

          padding: EdgeInsets.only(

            bottom: AppSpacing.xs,

            left: AppSpacing.sm,

          ),

          child: Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text('• ', style: base.copyWith(color: AppColors.gold)),

              Expanded(child: Text(block.content, style: base)),

            ],

          ),

        ),

      FormattedBlockType.citation => Padding(

          padding: EdgeInsets.only(bottom: AppSpacing.xs),

          child: Text(

            '[${block.content}]',

            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),

          ),

        ),

      FormattedBlockType.paragraph => Padding(

          padding: EdgeInsets.only(bottom: CraftsmanshipRhythm.paragraphGap),

          child: _RichInline(text: block.content, base: base),

        ),

    };

  }

}



class _RichInline extends StatelessWidget {

  const _RichInline({required this.text, required this.base});



  final String text;

  final TextStyle base;



  @override

  Widget build(BuildContext context) {

    final parts = text.split(RegExp(r'\*\*(.+?)\*\*'));

    if (parts.length == 1) return Text(text, style: base);



    return RichText(

      text: TextSpan(

        style: base,

        children: [

          for (var i = 0; i < parts.length; i++)

            TextSpan(

              text: parts[i],

              style: i.isOdd

                  ? base.copyWith(

                      fontWeight: FontWeight.w700,

                      color: AppColors.goldLight,

                    )

                  : null,

            ),

        ],

      ),

    );

  }

}



/// Code block with syntax-highlight-ready structure.

class _CodeBlock extends StatelessWidget {

  const _CodeBlock({required this.code, this.language});



  final String code;

  final String? language;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: AppSpacing.card,

      decoration: BoxDecoration(

        color: AppColors.primary.withValues(alpha: 0.6),

        borderRadius: AppRadius.md,

        border: Border.all(

          color: AppColors.gold.withValues(alpha: 0.15),

          width: AppBorderWidth.hairline,

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          if (language != null)

            Text(

              language!,

              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),

            ),

          Text(

            code,

            style: baseMono(),

          ),

        ],

      ),

    );

  }



  static TextStyle baseMono() {

    return TextStyle(

      fontFamily: 'monospace',

      fontSize: 13,

      color: AppColors.goldLight.withValues(alpha: 0.9),

      height: 1.55,

    );

  }

}


