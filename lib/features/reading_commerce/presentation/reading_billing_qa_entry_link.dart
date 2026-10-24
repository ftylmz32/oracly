/// QA-only door to the purchase screen. Store builds omit the dart-define.
library;

import 'package:flutter/widgets.dart';

import '../../../core/config/oracly_runtime_keys.dart';
import '../../../shared/widgets/oracly_quiet_link.dart';
import '../copy/reading_commerce_copy.dart';
import 'reading_commerce_route.dart';

class ReadingBillingQaEntryLink extends StatelessWidget {
  const ReadingBillingQaEntryLink({super.key, this.forceEnabled});

  /// Test seam. Release builds use [enabled].
  final bool? forceEnabled;

  static const enabled = bool.fromEnvironment(
    OraclyRuntimeKeys.readingBillingQa,
  );

  @override
  Widget build(BuildContext context) {
    if (!(forceEnabled ?? enabled)) return const SizedBox.shrink();
    return OraclyQuietLink(
      label: ReadingCommerceCopy.billingQaEntry,
      onTap: () => Navigator.of(context).push(readingCommerceRoute()),
    );
  }
}
