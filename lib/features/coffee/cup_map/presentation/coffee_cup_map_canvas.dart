/// One archived photo, zoomable and pannable, with the user's pins on top.
/// It draws only the photo: the frame (rim, radius, shadow) belongs to the
/// host's stage, so two photos crossfading never show two frames.
/// The child of the [InteractiveViewer] is laid out at the image's own
/// aspect ratio, so a tap's local position divided by the child size IS the
/// normalized image coordinate at any zoom. Pins are sized in scene units
/// divided by the current scale, so they stay a constant 44 px target.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../models/coffee_cup_map_record.dart';
import 'coffee_cup_map_motion.dart';
import 'coffee_cup_map_states.dart';

const double _pinTarget = 44;

/// Longest edge a kept photo is decoded at. Photos are captured at up to
/// 1920 px; 1600 keeps zoom detail and cuts each decoded photo to ~7.7 MB.
/// The aspect ratio is kept, so normalized pin coordinates are unaffected.
const int coffeeCupMapDecodeEdge = 1600;

/// The one image provider for a kept photo (canvas, precache, eviction).
ImageProvider coffeeCupMapPhotoImage(String path) => ResizeImage(
      FileImage(File(path)),
      width: coffeeCupMapDecodeEdge,
      height: coffeeCupMapDecodeEdge,
      policy: ResizeImagePolicy.fit,
      allowUpscaling: false,
    );

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
    this.onAspect,
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

  /// Width / height of the photo once decoded (reported after the frame), so
  /// the host can size its stage to this photo instead of leaving bands.
  final ValueChanged<double>? onAspect;

  @override
  State<CoffeeCupMapCanvas> createState() => CoffeeCupMapCanvasState();
}

class CoffeeCupMapCanvasState extends State<CoffeeCupMapCanvas>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _reset = AnimationController(
    vsync: this,
    duration: CoffeeCupMapMotion.zoomReset,
  );
  Animation<Matrix4>? _resetTween;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;
  bool _failed = false;
  Size _childSize = Size.zero;
  bool _zoomed = false;

  /// Pins already there when this photo was shown: only later ones animate in.
  late Set<String> _shownPins = {for (final p in widget.pins) p.id};

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    _reset.addListener(() {
      final tween = _resetTween;
      if (tween != null) _transform.value = tween.value;
    });
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
      _reset.stop();
      _zoomed = false;
      _transform.value = Matrix4.identity();
      _imageSize = null;
      _failed = false;
      _shownPins = {for (final p in widget.pins) p.id};
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
    final stream =
        coffeeCupMapPhotoImage(widget.photo.path).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        setState(() => _imageSize = size);
        // May fire synchronously inside initState (cached photo): tell the
        // host after this frame, never during its build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onAspect?.call(size.width / size.height);
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
    _reset.dispose();
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  /// Glides back to the whole photo (instant with reduced motion).
  void resetZoom() {
    if (CoffeeCupMapMotion.reduced(context)) {
      _transform.value = Matrix4.identity();
      return;
    }
    _resetTween = Matrix4Tween(
      begin: _transform.value.clone(),
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(parent: _reset, curve: CoffeeCupMapMotion.ease));
    _reset.forward(from: 0);
  }

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
    if (_failed) return const CoffeeCupMapMissingContent();
    final imageSize = _imageSize;
    if (imageSize == null) {
      return const CoffeeCupMapLoadingContent();
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
        final photo = SizedBox(
          width: width,
          height: height,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 6,
            clipBehavior: Clip.hardEdge,
            onInteractionStart: (_) => _reset.stop(),
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
                      child: Image(
                        image: coffeeCupMapPhotoImage(widget.photo.path),
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
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
                              key: ValueKey(widget.pins[i].id),
                              left: widget.pins[i].x * width - side / 2,
                              top: widget.pins[i].y * height - side / 2,
                              width: side,
                              height: side,
                              child: _PinMarker(
                                number: i + 1,
                                pin: widget.pins[i],
                                appear: !_shownPins.contains(widget.pins[i].id),
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
        );
        return Center(
          child: TweenAnimationBuilder<double>(
            // The photo settles in once, when it first decodes.
            tween: Tween(begin: 0, end: 1),
            duration: CoffeeCupMapMotion.of(
              context,
              CoffeeCupMapMotion.photoFirstFade,
            ),
            curve: CoffeeCupMapMotion.ease,
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: photo,
          ),
        );
      },
    );
  }
}

class _PinMarker extends StatefulWidget {
  const _PinMarker({
    required this.number,
    required this.pin,
    required this.appear,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final CoffeeCupMapPin pin;

  /// A pin the user just placed settles in once; existing pins do not.
  final bool appear;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PinMarker> createState() => _PinMarkerState();
}

class _PinMarkerState extends State<_PinMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: CoffeeCupMapMotion.pinAppear,
    value: widget.appear ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_in.value < 1) {
      if (CoffeeCupMapMotion.reduced(context)) {
        _in.value = 1;
      } else if (!_in.isAnimating) {
        _in.forward();
      }
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectDuration =
        CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.pinSelect);
    final settle = CurvedAnimation(parent: _in, curve: CoffeeCupMapMotion.ease);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: CoffeeCupMapCopy.pinSemantics(widget.number, widget.pin.note),
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Drawn in a fixed 44-unit box, then scaled with the slot so the
        // marker reads the same at every zoom.
        child: FittedBox(
          child: SizedBox.square(
            dimension: _pinTarget,
            child: FadeTransition(
              opacity: settle,
              child: ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(settle),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // One quiet ring while selected.
                    AnimatedOpacity(
                      opacity: widget.selected ? 1 : 0,
                      duration: selectDuration,
                      curve: CoffeeCupMapMotion.ease,
                      child: AnimatedScale(
                        scale: widget.selected ? 1 : 0.8,
                        duration: selectDuration,
                        curve: CoffeeCupMapMotion.ease,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: OraclyChrome.goldLight.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedScale(
                      scale: widget.selected ? 1.12 : 1,
                      duration: selectDuration,
                      curve: CoffeeCupMapMotion.ease,
                      child: CoffeeCupMapMedallion(
                        number: widget.number,
                        emphasized: widget.selected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
