import 'package:flutter/material.dart';

import 'cosmic_background.dart';

/// Screen shell with cosmic background — unified ORACLY frame.
class OraclyScaffold extends StatelessWidget {
  const OraclyScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showParticles = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showParticles;

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      showParticles: showParticles,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
