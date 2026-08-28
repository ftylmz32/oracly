/// Quiet live-vs-local source line for chat and OR'a Sor.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/ai_source_copy.dart';
import '../../../../core/widgets/transparency_footnote.dart';

class AiSourceFootnote extends StatelessWidget {
  const AiSourceFootnote({
    super.key,
    required this.fromAi,
    this.orAsk = false,
    this.padding,
  });

  final bool fromAi;
  final bool orAsk;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return TransparencyFootnote(
      text: orAsk
          ? AiSourceCopy.orAskFootnote(fromAi: fromAi)
          : AiSourceCopy.surfaceNote(fromAi: fromAi),
      padding: padding,
    );
  }
}
