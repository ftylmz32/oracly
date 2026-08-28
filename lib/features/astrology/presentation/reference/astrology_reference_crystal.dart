/// Crystal gem capsule - delegates to shared ORACLY gem chrome.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_crystal_capsule.dart';

class AstrologyReferenceCrystal extends StatelessWidget {
  const AstrologyReferenceCrystal({
    super.key,
    required this.count,
    this.onTap,
  });

  final String count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyCrystalCapsule(
      count: count,
      onTap: onTap,
    );
  }
}
