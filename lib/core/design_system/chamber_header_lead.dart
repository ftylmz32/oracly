/// Quiet purpose line under a chamber title.
library;

import 'package:flutter/material.dart';

import '../theme/reading_typography.dart';
import 'oracly_chrome.dart';

class ChamberHeaderLead extends StatelessWidget {
  const ChamberHeaderLead({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: ReadingTypography.opening(
        color: OraclyChrome.cream.withValues(alpha: 0.84),
      ).copyWith(fontSize: 14, height: 1.4),
    );
  }
}
