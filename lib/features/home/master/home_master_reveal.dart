/// Fast staggered Home section reveal.
library;

import 'package:flutter/material.dart';

import '../../../shared/widgets/oracly_entrance.dart';

class HomeMasterReveal extends StatelessWidget {
  const HomeMasterReveal({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  static const _step = Duration(milliseconds: 42);
  static const _enter = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    return OraclyEntrance.staggered(
      index: index,
      step: _step,
      duration: _enter,
      mode: OraclyEntranceMode.fadeUp,
      offset: 8,
      child: child,
    );
  }
}
