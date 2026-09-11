import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/controllers/game_controller.dart';
import 'package:chessclock/domain/clock.dart';
import 'support.dart';

void main() {
  testWidgets('deadline, one alarm per game, old timers cancelled', (
    tester,
  ) async {
    var now = 0;
    final device = FakeDevice();
    final c = GameController(
      engine: ClockEngine(ClockConfig(limitsMs: [1000, 1000]), () => now),
      device: device,
    );
    c.start();
    now = 500000;
    c.pause();
    now = 5000000;
    await tester.pump(const Duration(seconds: 2));
    expect(device.alarms, 0);
    c.resume();
    now += 500000;
    await tester.pump(const Duration(milliseconds: 500));
    expect(device.alarms, 1);
    c.frame();
    c.press(0);
    expect(device.alarms, 1);
    c.reset();
    c.start();
    now += 1000000;
    c.frame();
    expect(device.alarms, 2);
    c.reset();
    await tester.pump(const Duration(seconds: 2));
    expect(device.alarms, 2);
    c.dispose();
  });
  testWidgets(
    'simultaneous contacts do not alternate twice and interruptions pause',
    (tester) async {
      var now = 0;
      final device = FakeDevice();
      final c = GameController(
        engine: ClockEngine(ClockConfig(), () => now),
        device: device,
      );
      c.start();
      c.pointerDown(1, 0);
      c.pointerDown(2, 1);
      expect(c.engine.moves, [1, 0]);
      c.pointerUp(1);
      c.pointerDown(3, 1);
      expect(c.engine.moves, [1, 0]);
      c.pointerUp(2);
      c.pointerUp(3);
      c.pointerDown(4, 1);
      expect(c.engine.moves, [1, 1]);
      now = 1000000;
      c.interrupt();
      expect(c.engine.phase, GamePhase.paused);
      expect(device.awake, false);
      expect(c.engine.pauseReason, contains('interrupción'));
      now += 30000000;
      c.frame();
      expect(device.alarms, 0);
      c.dispose();
    },
  );
}
