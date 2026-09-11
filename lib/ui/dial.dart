import 'dart:math';
import 'package:flutter/material.dart';

class ClockDial extends CustomPainter {
  final double fraction;
  final Color accent;
  final bool expired;
  ClockDial({
    required this.fraction,
    required this.accent,
    required this.expired,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2 - 5;
    if (radius <= 0) return;
    final paint = Paint();
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      Colors.black,
      5,
      true,
    );
    canvas.drawCircle(
      center,
      radius,
      paint
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffdce0e3), Color(0xff555e67), Color(0xffa7afb5)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    paint.shader = null;
    canvas.drawCircle(
      center,
      radius - 4,
      paint..color = const Color(0xfff2ead8),
    );
    final inner = radius - 11;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: inner),
      -pi / 2,
      2 * pi * fraction.clamp(0, 1),
      false,
      paint
        ..color = accent.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < 60; i++) {
      final angle = i * pi / 30 - pi / 2;
      final major = i % 5 == 0;
      final outer = radius - 17;
      final inside = outer - (major ? 9 : 4);
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * inside,
        center + Offset(cos(angle), sin(angle)) * outer,
        paint
          ..color = const Color(0xff424343)
          ..strokeWidth = major ? 2 : 1,
      );
    }
    final angle = fraction * 2 * pi - pi / 2;
    canvas.drawLine(
      center - Offset(cos(angle), sin(angle)) * radius * .14,
      center + Offset(cos(angle), sin(angle)) * radius * .64,
      paint
        ..color = const Color(0xff242a30)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, paint..color = const Color(0xff242a30));
    if (expired) {
      final flag = center + Offset(radius * .32, -radius * .36);
      canvas.drawLine(
        flag,
        flag + Offset(0, radius * .36),
        paint
          ..color = const Color(0xffa92522)
          ..strokeWidth = 3,
      );
      canvas.drawPath(
        Path()
          ..moveTo(flag.dx, flag.dy)
          ..relativeLineTo(radius * .26, radius * .08)
          ..relativeLineTo(-radius * .26, radius * .1)
          ..close(),
        paint..color = const Color(0xffa92522),
      );
    }
  }

  @override
  bool shouldRepaint(ClockDial old) =>
      fraction != old.fraction ||
      accent != old.accent ||
      expired != old.expired;
}
