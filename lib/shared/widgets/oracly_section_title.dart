/// Shared section title widget — delegates to design-system [OraclySectionLabel].
library;

import 'package:flutter/material.dart';

import '../../core/design_system/oracly_section_label.dart';

/// Compatibility wrapper — prefer [OraclySectionLabel] for new code.
class OraclySectionTitle extends StatelessWidget {
  const OraclySectionTitle({
    super.key,
    required this.label,
    this.showDivider = true,
    this.compact = true,
    this.tracking = 2.8,
    this.fontSize = 11,
  });

  final String label;
  final bool showDivider;
  final bool compact;
  final double tracking;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return OraclySectionLabel(
      label: label,
      showDivider: showDivider,
      tracking: tracking,
      fontSize: fontSize,
    );
  }
}
