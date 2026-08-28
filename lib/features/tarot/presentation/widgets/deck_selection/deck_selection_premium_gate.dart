/// Premium deck access — routes free users to membership without fake grant.
library;

import 'package:flutter/material.dart';

import '../../../../../features/premium/services/premium_access.dart';
import 'deck_selection_data.dart';

abstract final class DeckSelectionPremiumGate {
  DeckSelectionPremiumGate._();

  static bool allow(BuildContext context, TarotDeckOption deck) {
    if (!deck.requiresPremium) return true;
    if (PremiumAccess.ensure(context)) return true;
    PremiumAccess.prompt(context);
    return false;
  }
}
