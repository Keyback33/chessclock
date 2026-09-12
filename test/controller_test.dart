import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/controllers/game_controller.dart';
import 'package:chessclock/domain/clock.dart';
import 'support.dart';

void main() {
  testWidgets('expiration on pause does not silence the new endgame audio', (
    tester,
  ) async {
    var now = 0;
    final device = FakeDevice();
    final c = GameController(
      engine: ClockEngine(ClockConfig(limitsMs: [1000, 1000]), () => now),
      device: device,
    );
    c.start();
    now = 1000000;
    c.pause();
    expect(c.engine.phase, GamePhase.finished);
    expect(device.events, ['silence', 'alarm']);
    c.frame();
    c.setOrientation(ClockOrientation.landscape);
    expect(device.alarms, 1);
    c.dispose();
  });

  testWidgets(
    'muted finish keeps vibration and recovered result stays silent',
    (tester) async {
      var now = 0;
      final device = FakeDevice();
      final c = GameController(
        engine: ClockEngine(
          ClockConfig(limitsMs: [1000, 1000], sound: false, vibration: true),
          () => now,
        ),
        device: device,
      );
      c.start();
      now = 1000000;
      c.frame();
      expect(device.alarmOptions.single, (sound: false, vibration: true));
      final saved = c.engine.snapshot();
      c.dispose();
      final recoveredDevice = FakeDevice();
      final recovered = GameController(
        engine: ClockEngine(ClockConfig(), () => now),
        device: recoveredDevice,
        recovery: saved,
      );
      recovered.recover();
      recovered.frame();
      recovered.press(0);
      expect(recovered.engine.phase, GamePhase.finished);
      expect(recoveredDevice.alarms, 0);
      recovered.dispose();
    },
  );

  testWidgets('one click per accepted move, including semantic activation', (
    tester,
  ) async {
    final device = FakeDevice();
    final c = GameController(
      engine: ClockEngine(ClockConfig(), () => 0),
      device: device,
    );
    c.press(0);
    expect(device.clicks, 0);
    c.start();
    c.pointerDown(1, 1); // Inactive panel.
    c.pointerUp(1);
    expect(device.clicks, 0);
    c.pointerDown(2, 0);
    c.pointerDown(3, 1); // Simultaneous contact is blocked.
    expect(device.clicks, 1);
    c.pointerUp(2);
    c.pointerDown(4, 1); // Still latched until all fingers lift.
    expect(device.clicks, 1);
    c.pointerUp(3);
    c.pointerUp(4);
    c.press(1); // Accessibility uses the same feedback path.
    expect(device.clicks, 2);
    expect(c.engine.moves, [1, 1]);
    c.pause();
    c.press(0);
    c.resume();
    expect(device.clicks, 2);
    c.dispose();
  });

  testWidgets('sound preference mutes moves and takes effect on resume', (
    tester,
  ) async {
    final device = FakeDevice();
    final c = GameController(
      engine: ClockEngine(ClockConfig(sound: false), () => 0),
      device: device,
    );
    c.start();
    c.press(0);
    expect(c.engine.moves, [1, 0]);
    expect(device.clicks, 0);
    c.pause();
    c.audio(true, false);
    c.resume();
    c.press(1);
    expect(device.clicks, 1);
    c.dispose();
  });

  testWidgets('expiration detected by a press plays only the alarm', (
    tester,
  ) async {
    var now = 0;
    final device = FakeDevice();
    final c = GameController(
      engine: ClockEngine(ClockConfig(limitsMs: [1000, 1000]), () => now),
      device: device,
    );
    c.start();
    now = 1000000;
    c.pointerDown(1, 0);
    expect(c.engine.phase, GamePhase.finished);
    expect(c.engine.moves, [0, 0]);
    expect(device.clicks, 0);
    expect(device.alarms, 1);
    c.press(0);
    expect(device.clicks, 0);
    c.dispose();
  });

  testWidgets('audio failure does not delay or undo a move', (tester) async {
    final device = FakeDevice()..failClick = true;
    final c = GameController(
      engine: ClockEngine(ClockConfig(), () => 0),
      device: device,
    );
    c.start();
    c.press(0);
    expect(c.engine.activePlayer, 1);
    expect(c.engine.moves, [1, 0]);
    await tester.pump();
    expect(c.notice, isNotNull);
    c.dispose();
  });

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
