import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../../features/discovery_share/widgets/discovery_share_action.dart';
import 'tarot_buttons.dart';

class TarotReadingActions extends StatelessWidget {
  const TarotReadingActions({
    super.key,
    required this.highlight,
    this.cardName = '',
    this.cardAsset,
    this.isReversed = false,
  });

  final String highlight;
  final String cardName;
  final String? cardAsset;
  final bool isReversed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TarotGlassButton(
            label: OraclyL10n.t('tarot.action.again'),
            icon: Icons.refresh_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DiscoveryShareAction(
            discovery: DiscoveryShareBuilder.tarot(
              theme: highlight,
              cardName: cardName,
              cardAsset: cardAsset,
              isReversed: isReversed,
            ),
          ),
        ),
      ],
    );
  }
}
