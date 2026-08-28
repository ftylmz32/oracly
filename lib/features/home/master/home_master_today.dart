/// Bugunun Izi - real daily ritual section chrome.
library;

import 'package:flutter/material.dart';

import '../reference/home_today_trace.dart';

class HomeMasterToday extends StatelessWidget {
  const HomeMasterToday({super.key, this.height});

  /// Preferred **card** height (section label sits above).
  final double? height;

  static String get label => HomeTodayTrace.label;

  @override
  Widget build(BuildContext context) => HomeTodayTrace(height: height);
}
