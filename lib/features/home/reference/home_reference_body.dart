/// Reference Home viewport stack — one portrait frame, no vertical scroll.
library;

import 'package:flutter/material.dart';

import '../master/home_master_body.dart';

/// Delegates to the single production Home body.
class HomeReferenceBody extends StatelessWidget {
  const HomeReferenceBody({super.key});

  @override
  Widget build(BuildContext context) => const HomeMasterBody();
}
