/// What / earn / spend — honest gem literacy without shop pressure.
library;

import 'package:flutter/material.dart';

import '../../copy/gems_copy.dart';
import 'gems_reference_cards.dart';
import 'gems_reference_tokens.dart';

class GemsExplainSection extends StatelessWidget {
  const GemsExplainSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GemsInfoCard(title: GemsCopy.whatTitle, body: GemsCopy.whatBody),
        SizedBox(height: GemsReferenceTokens.rowGap),
        GemsInfoCard(title: GemsCopy.earnTitle, body: GemsCopy.earnBody),
        SizedBox(height: GemsReferenceTokens.rowGap),
        GemsInfoCard(title: GemsCopy.spendTitle, body: GemsCopy.spendBody),
      ],
    );
  }
}