import 'dart:async';
import 'package:flutter/material.dart';

/// Visual latch only: the panel accepts the move immediately on pointer down.
/// The 17 frames per player preserve the approved geometry and metal reflections.
class MoveButton extends StatefulWidget {
  static const asset = 'assets/images/move_button.png';
  // Crop only the transparent padding above/below the rendered artwork.
  static const aspectRatio = 296 / 200;
  final bool raised;
  final int player;

  const MoveButton({super.key, required this.raised, required this.player});

  @override
  State<MoveButton> createState() => _MoveButtonState();
}

class _MoveButtonState extends State<MoveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _depth = AnimationController(
    vsync: this,
    value: widget.raised ? 0 : 1,
  );
  Timer? _release;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _release?.cancel();
      _depth.value = widget.raised ? 0 : 1;
    }
  }

  @override
  void didUpdateWidget(MoveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.raised == widget.raised) return;
    _release?.cancel();
    if (_reduceMotion) {
      _depth.value = widget.raised ? 0 : 1;
    } else if (widget.raised) {
      _depth.stop();
      _release = Timer(const Duration(milliseconds: 70), () {
        if (!mounted || !widget.raised) return;
        _depth.animateTo(
          0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
        );
      });
    } else {
      _depth.animateTo(
        1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _release?.cancel();
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LayoutBuilder(
      builder: (context, box) {
        final tileHeight = box.maxWidth * 250 / 296;
        final crop = (tileHeight - box.maxHeight) / 2;
        return AnimatedBuilder(
          animation: _depth,
          child: Image.asset(
            MoveButton.asset,
            width: box.maxWidth * 6,
            height: tileHeight * 6,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            gaplessPlayback: true,
          ),
          builder: (context, image) {
            final frame = widget.player * 17 + (_depth.value * 16).round();
            return ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: box.maxWidth * 6,
                maxWidth: box.maxWidth * 6,
                minHeight: tileHeight * 6,
                maxHeight: tileHeight * 6,
                child: Transform.translate(
                  offset: Offset(
                    -(frame % 6) * box.maxWidth,
                    -(frame ~/ 6) * tileHeight - crop,
                  ),
                  child: image,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
