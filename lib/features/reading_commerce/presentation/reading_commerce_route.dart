import 'package:flutter/widgets.dart';

import '../../../core/navigation/oracly_page_transitions.dart';
import 'reading_commerce_screen.dart';

Route<T> readingCommerceRoute<T>({RouteSettings? settings}) {
  return OraclyPageTransitions.light<T>(
    page: const ReadingCommerceScreen(),
    settings: settings,
  );
}
