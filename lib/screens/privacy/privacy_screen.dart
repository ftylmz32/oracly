/// EPIC-014 — Privacy controls with honest, calm communication.
library;

import 'package:flutter/material.dart';

import '../../features/privacy/presentation/screens/privacy_control_center_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivacyControlCenterScreen();
  }
}
