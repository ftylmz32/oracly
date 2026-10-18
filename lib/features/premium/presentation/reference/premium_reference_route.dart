/// Route stays beside the screen so callers keep one import.
library;

import 'package:flutter/widgets.dart';

import '../../../../core/navigation/oracly_page_transitions.dart';
import 'premium_reference_screen.dart';

Route<T> premiumScreenRoute<T>({RouteSettings? settings}) {
  return OraclyPageTransitions.light<T>(
    page: const PremiumReferenceScreen(),
    settings: settings,
  );
}
