import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/chamber_waiting_orb.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../../reading_operation/providers/reading_live_provider.dart';
import '../copy/reading_commerce_copy.dart';
import '../models/reading_commerce_view.dart';
import '../services/reading_commerce_buyer.dart';
import 'reading_commerce_body.dart';

class ReadingCommerceScreen extends ConsumerStatefulWidget {
  const ReadingCommerceScreen({super.key, this.view, this.buyer});

  /// Test seam. Production loads the server catalog and the store.
  final ReadingCommerceView? view;
  final ReadingCommerceBuyer? buyer;

  @override
  ConsumerState<ReadingCommerceScreen> createState() =>
      _ReadingCommerceScreenState();
}

class _ReadingCommerceScreenState extends ConsumerState<ReadingCommerceScreen> {
  ReadingCommerceView? _view;
  String? _message;

  @override
  void initState() {
    super.initState();
    _view = widget.view;
    if (widget.view == null) Future.microtask(_load);
  }

  Future<void> _load() async {
    final send = ref.read(readingOperationSenderProvider);
    final buyer = widget.buyer ?? ReadingCommerceBuyer();
    if (send == null) {
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
        ? await buyer.storePrices()
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
    final send = ref.read(readingOperationSenderProvider);
    final buyer = widget.buyer ?? ReadingCommerceBuyer();
    if (send == null) return;
    final platform = Theme.of(context).platform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    final result = await buyer.buy(
      productId: productId,
      verify: (token) async {
        final wire = await send('POST', '/v1/reading-entitlements/verify', {
          'platform': platform,
          'productId': productId,
          'purchaseToken': token,
        });
        return wire?.json?['data']?['granted'] == true;
      },
    );
    if (!mounted) return;
    setState(() {
      _message = switch (result.kind) {
        ReadingBuyKind.granted => ReadingCommerceCopy.granted,
        ReadingBuyKind.pending => ReadingCommerceCopy.pending,
        ReadingBuyKind.canceled => ReadingCommerceCopy.canceled,
        ReadingBuyKind.failed => ReadingCommerceCopy.failed,
      };
    });
    if (result.kind == ReadingBuyKind.granted) await _load();
  }
}
