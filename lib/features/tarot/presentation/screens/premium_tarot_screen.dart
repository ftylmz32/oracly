/// OR-1090 — Premium tarot route entry (delegates to PremiumReferenceScreen).
library;

export '../../../premium/presentation/reference/premium_reference_screen.dart';

import 'package:flutter/material.dart';

import '../../../premium/presentation/reference/premium_reference_screen.dart';

/// Backward-compatible alias for tarot navigator.
typedef PremiumTarotScreen = PremiumReferenceScreen;

/// Opens the luxury membership experience.
void openPremiumScreen(BuildContext context) {
  Navigator.of(context).push(premiumScreenRoute());
}
