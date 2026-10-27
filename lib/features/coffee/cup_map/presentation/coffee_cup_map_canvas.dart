/// One archived photo, zoomable and pannable, with the user's pins on top.
/// The child of the [InteractiveViewer] is laid out at the image's own
/// aspect ratio, so a tap's local position divided by the child size IS the
/// normalized image coordinate at any zoom. Pins are sized in scene units
/// divided by the current scale, so they stay a constant 44 px target.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../models/coffee_cup_map_record.dart';

const double _pinTarget = 44;

class CoffeeCupMapCanvas extends StatefulWidget {
  const CoffeeCupMapCanvas({
    super.key,
    required this.photo,
    required this.pins,
    required this.maxHeight,
    required this.onTapAt,
    required this.onPinTap,
    this.selectedPinId,
    this.onZoomChanged,
  });

  final CoffeeCupMapPhoto photo;

  /// Pins of THIS photo, in display order (index + 1 = the pin's number).
  final List<CoffeeCupMapPin> pins;
  final double maxHeight;
  final void Function(double x, double y) onTapAt;
  final ValueChanged<CoffeeCupMapPin> onPinTap;
  final String? selectedPinId;

  /// `true` while zoomed in — the host stops its own scrolling so one-finger
  /// drags pan the photo instead.
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<CoffeeCupMapCanvas> createState() => CoffeeCupMapCanvasState();
}

class CoffeeCupMapCanvasState extends State<CoffeeCupMapCanvas> {
  final TransformationController _transform = TransformationController();
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;
  bool _failed = false;
  Size _childSize = Size.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    _resolve();
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged?.call(zoomed);
  }

  @override
  void didUpdateWidget(covariant CoffeeCupMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.path != widget.photo.path) {
      // Mid-build: reset silently (the host already dropped its zoom flag).
      _zoomed = false;
      _transform.value = Matrix4.identity();
      _imageSize = null;
      _failed = false;
      _resolve();
    }
  }

  void _resolve() {
    _detach();
    final file = File(widget.photo.path);
    if (!file.existsSync()) {
      _failed = true;
      return;
    }
    final stream = FileImage(file).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _detach() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  void resetZoom() => _transform.value = Matrix4.identity();

  /// The normalized image point at the middle of what is visible now.
  Offset? visibleCenter() {
    if (_childSize.isEmpty) return null;
    final scene = _transform.toScene(
      Offset(_childSize.width / 2, _childSize.height / 2),
    );
    return Offset(
      (scene.dx / _childSize.width).clamp(0.0, 1.0),
      (scene.dy / _childSize.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _MissingPhoto(height: math.min(widget.maxHeight, 220));
    }
    final imageSize = _imageSize;
    if (imageSize == null) {
      return SizedBox(
        height: math.min(widget.maxHeight, 220),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect = imageSize.width / imageSize.height;
        var width = constraints.maxWidth;
        var height = width / aspect;
        if (height > widget.maxHeight) {
          height = widget.maxHeight;
          width = height * aspect;
        }
        _childSize = Size(width, height);
        return Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: CoffeeReferenceTokens.cupWell,
              borderRadius: OraclyChrome.cardRadius,
              boxShadow: CoffeeReferenceTokens.cupFrameShadows(),
            ),
            // A border in `decoration` would inset the viewer by its width
            // and skew every normalized tap; drawn on top it does not.
            foregroundDecoration: BoxDecoration(
              borderRadius: OraclyChrome.cardRadius,
              border: Border.all(
                color: OraclyChrome.gold.withValues(
                  alpha: OraclyChrome.borderDefault,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: 6,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // The host's labelled action covers screen readers.
                        excludeFromSemantics: true,
                        onTapUp: (details) => widget.onTapAt(
                          (details.localPosition.dx / width).clamp(0.0, 1.0),
                          (details.localPosition.dy / height).clamp(0.0, 1.0),
                        ),
                        child: Image.file(
                          File(widget.photo.path),
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _transform,
                      builder: (context, _) {
                        final scale = _transform.value.getMaxScaleOnAxis();
                        final side = _pinTarget / scale;
                        return Stack(
                          children: [
                            for (var i = 0; i < widget.pins.length; i++)
                              Positioned(
                                left: widget.pins[i].x * width - side / 2,
                                top: widget.pins[i].y * height - side / 2,
                                width: side,
                                height: side,
                                child: _PinMarker(
                                  number: i + 1,
                                  pin: widget.pins[i],
                                  selected:
                                      widget.pins[i].id == widget.selectedPinId,
                                  onTap: () => widget.onPinTap(widget.pins[i]),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.number,
    required this.pin,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final CoffeeCupMapPin pin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: CoffeeCupMapCopy.pinSemantics(number, pin.note),
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Drawn in a fixed 44-unit box, then scaled with the slot so the
        // marker reads the same at every zoom.
        child: FittedBox(
          child: SizedBox.square(
            dimension: _pinTarget,
            child: Center(
              child: Container(
                width: selected ? 30 : 26,
                height: selected ? 30 : 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OraclyChrome.midnight.withValues(alpha: 0.86),
                  border: Border.all(
                    color: selected ? OraclyChrome.goldLight : OraclyChrome.gold,
                    width: selected ? 2.4 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OraclyChrome.gold.withValues(
                        alpha: selected ? 0.55 : 0.32,
                      ),
                      blurRadius: selected ? 12 : 8,
                    ),
                  ],
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: OraclyChrome.cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OraclyChrome.cardSurface.withValues(alpha: 0.6),
        borderRadius: OraclyChrome.cardRadius,
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderHairline),
        ),
      ),
      child: Text(
        CoffeeCupMapCopy.photoMissing,
        textAlign: TextAlign.center,
        style: const TextStyle(color: OraclyChrome.cream, height: 1.4),
      ),
    );
  }
}
