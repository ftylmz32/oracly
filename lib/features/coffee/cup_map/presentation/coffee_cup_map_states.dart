/// Fincan Haritası building blocks shared by the door, the map and the note
/// sheet: the pin medallion and the calm frames shown while a photo loads,
/// when it is gone, and when a reading has no map.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../copy/coffee_cup_map_copy.dart';

/// The numbered gold-rimmed disc used for a pin everywhere.
class CoffeeCupMapMedallion extends StatelessWidget {
  const CoffeeCupMapMedallion({
    super.key,
    required this.number,
    this.size = 26,
    this.emphasized = false,
  });

  final int number;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            OraclyChrome.deepNavy.withValues(alpha: 0.94),
            OraclyChrome.midnight.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(
          color: emphasized ? OraclyChrome.goldLight : OraclyChrome.gold,
          width: emphasized ? 2 : 1.4,
        ),
        boxShadow: [
          // Lifts the disc off any photo, light or dark.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
          BoxShadow(
            color: OraclyChrome.gold.withValues(
              alpha: emphasized ? OraclyChrome.glowStrong : OraclyChrome.glowSoft,
            ),
            blurRadius: emphasized ? 10 : 6,
          ),
        ],
      ),
      child: Text(
        '$number',
        // A fixed-size graphic: the number is in every label, so it does not
        // grow with the text size and spill out of the disc.
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: OraclyChrome.cream,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// The empty frame a photo sits in: same radius and rim as the photo, so a
/// loading or missing state never changes the layout around it.
class CoffeeCupMapPhotoFrame extends StatelessWidget {
  const CoffeeCupMapPhotoFrame({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.heroRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclyChrome.deepNavy.withValues(alpha: 0.72),
            OraclyChrome.midnight.withValues(alpha: 0.86),
          ],
        ),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderHairline),
        ),
      ),
      child: child,
    );
  }
}

/// The loading stage before a map is known: the content below in a frame.
class CoffeeCupMapLoadingFrame extends StatelessWidget {
  const CoffeeCupMapLoadingFrame({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return CoffeeCupMapPhotoFrame(
      height: height,
      child: const CoffeeCupMapLoadingContent(),
    );
  }
}

/// While a photo decodes: a still gold ring with a slow, faint breath (rests
/// on reduced motion and constrained devices). No spinner, no frame of its
/// own (the stage frames it).
class CoffeeCupMapLoadingContent extends StatefulWidget {
  const CoffeeCupMapLoadingContent({super.key});

  @override
  State<CoffeeCupMapLoadingContent> createState() =>
      _CoffeeCupMapLoadingContentState();
}

class _CoffeeCupMapLoadingContentState extends State<CoffeeCupMapLoadingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.6);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: CoffeeCupMapCopy.photoLoading,
      child: ExcludeSemantics(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: Tween(begin: 0.35, end: 0.9).animate(_breath),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: OraclyChrome.gold.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                CoffeeCupMapCopy.photoLoading,
                textAlign: TextAlign.center,
                style: ReadingTypography.micro(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photo was removed from the device; the pins stay listed below.
class CoffeeCupMapMissingContent extends StatelessWidget {
  const CoffeeCupMapMissingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hide_image_outlined,
              size: 26,
              color: OraclyChrome.gold.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 12),
            Text(
              CoffeeCupMapCopy.photoMissing,
              textAlign: TextAlign.center,
              style: ReadingTypography.secondary(),
            ),
          ],
        ),
      ),
    );
  }
}

/// No map for this reading (older reading, another account, deleted).
class CoffeeCupMapUnavailable extends StatelessWidget {
  const CoffeeCupMapUnavailable({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OraclyChrome.deepNavy.withValues(alpha: 0.6),
                border: Border.all(
                  color: OraclyChrome.gold.withValues(
                    alpha: OraclyChrome.borderDefault,
                  ),
                ),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 26,
                color: OraclyChrome.gold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              CoffeeCupMapCopy.mapUnavailable,
              textAlign: TextAlign.center,
              style: ReadingTypography.secondary(),
            ),
            const SizedBox(height: 12),
            OraclyTextAction(label: CoffeeCupMapCopy.back, onPressed: onBack),
          ],
        ),
      ),
    );
  }
}
