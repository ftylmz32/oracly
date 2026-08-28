/// OR Home entry — flagship CTA wired to canonical /chat.
library;

import 'package:flutter/material.dart';

import 'home_reference_or_flagship.dart';

/// Preserved type for reachability tests; presentation is the flagship card.
class HomeReferenceOrGuideSection extends StatelessWidget {
  const HomeReferenceOrGuideSection({
    super.key,
    this.compact = true,
    this.height,
  });

  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return HomeReferenceOrFlagship(height: height ?? 132);
  }
}
