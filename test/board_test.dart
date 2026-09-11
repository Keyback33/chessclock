import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/app.dart';
import 'package:chessclock/controllers/game_controller.dart';
import 'package:chessclock/domain/clock.dart';
import 'support.dart';

void main() {
  testWidgets('start, touch, inactive touch, pause, resume and reset', (
    tester,
  ) async {
    var now = 0;
    final c = GameController(
      engine: ClockEngine(ClockConfig(), () => now),
      device: FakeDevice(),
    );
    await tester.pumpWidget(ChessClockApp(controller: c));
    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pump();
    now = 1000000;
    await tester.tap(find.byKey(const ValueKey('panel-1')));
    expect(c.engine.activePlayer, 0);
    final finger = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('panel-0'))),
      pointer: 1,
    );
    final other = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('panel-1'))),
      pointer: 2,
    );
    expect(c.engine.moves, [1, 0]);
    await finger.up();
    await other.up();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pause')));
    await tester.pump();
    expect(c.engine.phase, GamePhase.paused);
    await tester.tap(find.byKey(const ValueKey('resume')));
    await tester.pump();
    expect(c.engine.activePlayer, 1);
    await tester.tap(find.byKey(const ValueKey('reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reiniciar'));
    await tester.pumpAndSettle();
    expect(c.engine.phase, GamePhase.ready);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  for (final size in [
    const Size(320, 568),
    const Size(412, 892),
    const Size(1024, 600),
    const Size(800, 1280),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('layout ${size.width}x${size.height} text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final c = GameController(
          engine: ClockEngine(ClockConfig(), () => 0),
          device: FakeDevice(),
        );
        await tester.pumpWidget(ChessClockApp(controller: c));
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        final rotations = tester
            .widgetList<RotatedBox>(find.byType(RotatedBox))
            .map((r) => r.quarterTurns);
        expect(rotations, size.width > size.height ? [1, 3] : [2, 0]);
        await tester.tap(find.byKey(const ValueKey('start')));
        await tester.pump();
        expect(tester.takeException(), null);
        c.interrupt();
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        c.reset();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('settings')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }
  testWidgets('invalid input rejected, valid settings persist in controller', (
    tester,
  ) async {
    final c = GameController(
      engine: ClockEngine(ClockConfig(), () => 0),
      device: FakeDevice(),
    );
    await tester.pumpWidget(ChessClockApp(controller: c));
    await tester.tap(find.byKey(const ValueKey('settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('seconds-0')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('seconds-0')), '0');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save-settings')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-settings')));
    await tester.pump();
    expect(c.engine.config.limitsMs, [30000, 30000]);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('seconds-0')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('seconds-0')), '15');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save-settings')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-settings')));
    await tester.pumpAndSettle();
    expect(c.engine.config.limitsMs, [15000, 15000]);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
