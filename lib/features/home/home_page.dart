/// Home (Evren) screen entry - master presentation only.
///
/// LIVE PATH (do not bypass):
/// [OraclyAppShell] -> [HomePage] -> [HomeMasterPage]
///
/// Legacy reference/epic paths are NOT the live shell Home.
library;

import 'package:flutter/material.dart';

import 'master/home_master_page.dart';

/// Active Home - clean master composition root.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const HomeMasterPage();
}
