/// Live Home hero — daily ritual, not fake energy.
library;

import 'package:flutter/material.dart';

import '../../daily_ritual/widgets/daily_ritual_card.dart';

/// Delegates to [DailyRitualCard] so Home has one daily ritual surface.
class HomeReferenceHeroCard extends StatelessWidget {
  const HomeReferenceHeroCard({super.key});

  @override
  Widget build(BuildContext context) => const DailyRitualCard();
}
