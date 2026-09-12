import 'package:flutter/material.dart';

/// The panel owns input; this face follows the clock's mechanical latch.
class MoveButton extends StatelessWidget {
  final bool active;
  final Color accent;
  const MoveButton({super.key, required this.active, required this.accent});

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 90);
    final face = active ? accent : const Color(0xff495664);
    final rim = BorderRadius.circular(12);
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            top: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: rim,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(face, Colors.black, 0.35)!,
                    Color.lerp(face, Colors.black, 0.7)!,
                  ],
                ),
                border: Border.all(color: const Color(0xff11171d)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    offset: Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: duration,
            curve: Curves.easeOutCubic,
            top: active ? 0 : 5,
            left: 0,
            right: 0,
            height: 41,
            child: AnimatedContainer(
              duration: duration,
              decoration: BoxDecoration(
                borderRadius: rim,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.16, 0.78, 1],
                  colors: [
                    Color.lerp(face, Colors.white, active ? 0.55 : 0.25)!,
                    Color.lerp(face, Colors.white, 0.12)!,
                    face,
                    Color.lerp(face, Colors.black, 0.2)!,
                  ],
                ),
                border: Border.all(
                  color: Color.lerp(face, Colors.white, 0.45)!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x66000000),
                    offset: Offset(0, active ? 3 : 1),
                    blurRadius: active ? 2 : 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      active ? 'TERMINAR JUGADA' : 'chessclock',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: active
                            ? const Color(0xff20262d)
                            : const Color(0xffdce3ea),
                        shadows: [
                          Shadow(
                            color: active
                                ? const Color(0x66ffffff)
                                : const Color(0x99000000),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
