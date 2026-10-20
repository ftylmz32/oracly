import 'package:flutter/widgets.dart';

import '../../../shared/widgets/oracly_quiet_link.dart';
import '../copy/reading_commerce_copy.dart';
import 'reading_commerce_route.dart';

/// Opens the purchase screen. It never shows a price or a buy button.
class ReadingCreditLink extends StatelessWidget {
  const ReadingCreditLink({super.key});

  @override
  Widget build(BuildContext context) {
    return OraclyQuietLink(
      label: ReadingCommerceCopy.openCredits,
      onTap: () => Navigator.of(context).push(readingCommerceRoute()),
    );
  }
}
