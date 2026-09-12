import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/app.dart';
import 'package:chessclock/controllers/game_controller.dart';
import 'package:chessclock/domain/clock.dart';
import 'package:chessclock/ui/move_button.dart';
import 'support.dart';

Offset spriteOffset(WidgetTester tester, Finder button) {
  final transform = tester.widget<Transform>(
    find.descendant(of: button, matching: find.byType(Transform)),
  );
  final translation = transform.transform.getTranslation();
  final size = tester.getSize(button);
  return Offset(
    (translation.x / size.width).roundToDouble(),
    (translation.y / size.height).roundToDouble(),
  );
}

void main() {
  testWidgets(
    'plunger feedback never delays a move or repeats a held contact',
    (tester) async {
      var now = 0;
      final device = FakeDevice();
      final c = GameController(
        engine: ClockEngine(ClockConfig(), () => now),
        device: device,
      );
      await tester.pumpWidget(ChessClockApp(controller: c));
      c.start();
      await tester.pump(const Duration(milliseconds: 300));
      final first = find.byKey(const ValueKey('move-button-0'));
      final second = find.byKey(const ValueKey('move-button-1'));
      final firstUp = spriteOffset(tester, first);
      final secondDown = spriteOffset(tester, second);
      now = 1000000;
      final finger = await tester.startGesture(tester.getCenter(first));
      expect(c.engine.moves, [1, 0]);
      expect(c.engine.activePlayer, 1);
      expect(c.engine.valueUs(0), 29000000);
      expect(device.clicks, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(spriteOffset(tester, first), isNot(firstUp));
      expect(spriteOffset(tester, second), secondDown);
      final other = await tester.startGesture(
        tester.getCenter(second),
        pointer: 2,
      );
      expect(c.engine.moves, [1, 0]);
      await tester.pump(const Duration(milliseconds: 40));
      final firstDown = spriteOffset(tester, first);
      await tester.pump(const Duration(milliseconds: 200));
      expect(spriteOffset(tester, first), firstDown);
      expect(spriteOffset(tester, second), isNot(secondDown));
      c.pause();
      await tester.pump(const Duration(milliseconds: 300));
      expect(spriteOffset(tester, first), firstDown);
      expect(device.clicks, 1);
      await finger.up();
      await other.up();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'release is cancelled by another press, reduced motion or disposal',
    (tester) async {
      Future<void> show(bool raised, {bool reduce = false}) =>
          tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduce),
                child: Center(
                  child: SizedBox(
                    width: 148,
                    height: 125,
                    child: MoveButton(raised: raised, player: 0),
                  ),
                ),
              ),
            ),
          );
      await show(false);
      final button = find.byType(MoveButton);
      final down = spriteOffset(tester, button);
      await show(true);
      await tester.pump(const Duration(milliseconds: 30));
      await show(false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(spriteOffset(tester, button), down);
      await show(true, reduce: true);
      expect(spriteOffset(tester, button), Offset.zero);
      await show(false, reduce: true);
      expect(spriteOffset(tester, button), down);
      await show(true);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large dial, left aligned readout and plunger share the footer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final c = GameController(
      engine: ClockEngine(ClockConfig(), () => 0),
      device: FakeDevice(),
    );
    await tester.pumpWidget(ChessClockApp(controller: c));
    final time = tester.getRect(find.byKey(const ValueKey('time-0')));
    final status = tester.getRect(find.byKey(const ValueKey('status-0')));
    final readout = tester.getRect(find.byKey(const ValueKey('readout-0')));
    final button = tester.getRect(find.byKey(const ValueKey('move-button-0')));
    expect(time.left, closeTo(status.left, .01));
    expect(time.right, lessThan(button.left));
    expect(readout.center.dy, closeTo(button.center.dy, .01));
    expect(button.width, greaterThanOrEqualTo(140));
    expect(
      tester.getSize(find.byKey(const ValueKey('dial-0'))).width,
      greaterThan(200),
    );
    expect(
      find.descendant(of: find.byType(MoveButton), matching: find.byType(Text)),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
