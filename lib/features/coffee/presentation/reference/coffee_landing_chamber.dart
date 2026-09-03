/// Entry chrome — back · KAHVE FALI · live gem; landing scrolls in the chamber.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import 'coffee_reference_app_bar.dart';
import 'coffee_reference_atmosphere.dart';
import 'coffee_reference_tokens.dart';

class CoffeeLandingChamber extends StatelessWidget {
  const CoffeeLandingChamber({
    super.key,
    required this.onBack,
    required this.child,
  });

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const CoffeeReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: AppLayout.scrollBottomInset(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      CoffeeReferenceTokens.screenHorizontal,
                      CoffeeReferenceTokens.screenTop,
                      CoffeeReferenceTokens.screenHorizontal,
                      0,
                    ),
                    child: CoffeeReferenceAppBar(onBack: onBack),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
