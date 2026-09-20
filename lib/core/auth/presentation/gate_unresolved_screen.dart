/// Neutral, brand-safe placeholder for a deletion gate that has not
/// resolved yet — must NEVER claim anything about account-deletion state.
library;

import 'package:flutter/widgets.dart';

class GateUnresolvedScreen extends StatelessWidget {
  const GateUnresolvedScreen({super.key});

  static const midnight = Color(0xFF07050D);

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: midnight, child: SizedBox.expand());
}
