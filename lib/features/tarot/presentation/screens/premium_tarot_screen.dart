/// OR-1090 — Premium tarot route entry (delegates to PremiumScreen).
library;

export '../../../premium/presentation/screens/premium_screen.dart';

import 'package:flutter/material.dart';

import '../../../premium/presentation/screens/premium_screen.dart';

/// Backward-compatible alias for tarot navigator.
typedef PremiumTarotScreen = PremiumScreen;

/// Opens the luxury membership experience.
void openPremiumScreen(BuildContext context) {
  Navigator.of(context).push(premiumScreenRoute());
}
