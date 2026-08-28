/// Compatibility shim - live Home is [HomeMasterPage].
///
/// Kept so older tests that pump [HomeReferencePage] still hit the master root.
library;

import 'package:flutter/material.dart';

import '../master/home_master_page.dart';

/// Delegates to the single production Home presentation root.
class HomeReferencePage extends StatelessWidget {
  const HomeReferencePage({super.key});

  @override
  Widget build(BuildContext context) => const HomeMasterPage();
}
