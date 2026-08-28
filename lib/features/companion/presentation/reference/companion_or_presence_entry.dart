/// Short OR entry — emblem first, then text. No large animation.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../shared/widgets/oracly_entrance.dart';
import 'companion_or_living_tokens.dart';

class CompanionOrPresenceEntry extends StatelessWidget {
  const CompanionOrPresenceEntry({
    super.key,
    required this.emblem,
    required this.body,
  });

  final Widget emblem;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    if (OraclyQuietMotion.still(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [emblem, body],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OraclyEntrance(
          mode: OraclyEntranceMode.fade,
          offset: 0,
          child: emblem,
        ),
        OraclyEntrance(
          mode: OraclyEntranceMode.fade,
          offset: 0,
          delay: CompanionOrLivingTokens.entryTextDelay,
          child: body,
        ),
      ],
    );
  }
}
