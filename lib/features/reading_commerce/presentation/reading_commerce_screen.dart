import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/chamber_waiting_orb.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../../reading_operation/providers/reading_live_provider.dart';
import '../copy/reading_commerce_copy.dart';
import '../models/reading_commerce_view.dart';
import '../services/reading_purchase_binding.dart';
import '../services/reading_purchase_monitor.dart';
import '../services/reading_purchase_tracker.dart';
import 'reading_commerce_body.dart';

class ReadingCommerceScreen extends ConsumerStatefulWidget {
  const ReadingCommerceScreen({super.key, this.view});

  /// Test seam. Production loads the server catalog and the store.
  final ReadingCommerceView? view;

  @override
  ConsumerState<ReadingCommerceScreen> createState() =>
      _ReadingCommerceScreenState();
}

class _ReadingCommerceScreenState extends ConsumerState<ReadingCommerceScreen> {
  ReadingCommerceView? _view;
  String? _message;
  ReadingPurchaseMonitor? _monitor;

  @override
  void initState() {
    super.initState();
    _view = widget.view;
    if (widget.view != null) return;
    _monitor = ref.read(readingPurchaseMonitorProvider);
    _monitor!.addListener(_settled);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _monitor?.removeListener(_settled);
    super.dispose();
  }

  void _settled(ReadingBuyKind kind, String productId) {
    if (!mounted || kind != ReadingBuyKind.granted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
  }

  Future<void> _load() async {
    final send = ref.read(readingOperationSenderProvider);
    final monitor = _monitor;
    if (send == null || monitor == null) {
      if (mounted) setState(() => _view = ReadingCommerceView.closed());
      return;
    }
    final wire = await send('GET', '/v1/reading-entitlements/catalog', null);
    final data = wire?.json?['data'];
    if (data is! Map) {
      if (mounted) setState(() => _view = ReadingCommerceView.closed());
      return;
    }
    if (!mounted) return;
    final open = data['commerce'] == 'open';
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final platformAdmitted = ios
        ? data['iosAdmitted'] == true
        : data['androidAdmitted'] == true;
    final prices = open && data['purchasable'] == true && platformAdmitted
        ? await monitor.storePrices()
        : const <String, String>{};
    final balance = data['balance'];
    final coffee = balance is Map ? balance['coffee'] : 0;
    final palm = balance is Map ? balance['palm'] : 0;
    if (!mounted) return;
    setState(() {
      _view = ReadingCommerceView.decide(
        commerceOpen: open,
        purchasable: data['purchasable'] == true,
        platformAdmitted: platformAdmitted,
        storePrices: prices,
        coffeeCredits: coffee is int ? coffee : 0,
        palmCredits: palm is int ? palm : 0,
        message: prices.isEmpty && open && data['purchasable'] == true
            ? ReadingCommerceCopy.unavailable
            : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    return OraclyScaffold(
      child: view == null
          ? const Center(child: ChamberWaitingOrb())
          : ReadingCommerceBody(
              view: _message == null ? view : ReadingCommerceView(
                coffeeCredits: view.coffeeCredits,
                palmCredits: view.palmCredits,
                coffeePrice: view.coffeePrice,
                palmPrice: view.palmPrice,
                packPrice: view.packPrice,
                message: _message,
              ),
              onBuy: view.showCoffee || view.showPalm || view.showPack
                  ? _buy
                  : null,
            ),
    );
  }

  Future<void> _buy(String productId) async {
    final monitor = _monitor;
    if (monitor == null) return;
    final result = await monitor.buy(productId);
    if (!mounted || result == ReadingBuyKind.granted) return;
    setState(() {
      _message = switch (result) {
        ReadingBuyKind.granted => ReadingCommerceCopy.granted,
        ReadingBuyKind.pending => ReadingCommerceCopy.pending,
        ReadingBuyKind.canceled => ReadingCommerceCopy.canceled,
        ReadingBuyKind.failed => ReadingCommerceCopy.failed,
      };
    });
  }
}
