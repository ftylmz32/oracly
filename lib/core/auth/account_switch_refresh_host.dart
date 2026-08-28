/// Invalidates Riverpod caches after local data wipe on account switch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/privacy/services/privacy_data_refresh.dart';
import 'user_local_data_isolation.dart';

class AccountSwitchRefreshHost extends ConsumerStatefulWidget {
  const AccountSwitchRefreshHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AccountSwitchRefreshHost> createState() =>
      _AccountSwitchRefreshHostState();
}

class _AccountSwitchRefreshHostState
    extends ConsumerState<AccountSwitchRefreshHost> {
  @override
  void initState() {
    super.initState();
    UserLocalDataIsolation.accountSwitchEpoch.addListener(_onSwitch);
  }

  @override
  void dispose() {
    UserLocalDataIsolation.accountSwitchEpoch.removeListener(_onSwitch);
    super.dispose();
  }

  void _onSwitch() {
    PrivacyDataRefresh.afterAccountSwitch(ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
