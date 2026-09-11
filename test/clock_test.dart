import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/domain/clock.dart';

void main() {
  var now = 0;
  late ClockEngine e;
  setUp(() {
    now = 0;
    e = ClockEngine(ClockConfig(), () => now);
  });
  test('default ready and selected first player', () {
    expect(e.phase, GamePhase.ready);
    expect(e.valueUs(0), 30000000);
    expect(e.press(0), false);
    e.reset(ClockConfig(firstPlayer: 1));
    e.start();
    expect(e.activePlayer, 1);
    expect(e.start(), false);
  });
  test('per move renews independent limits and preserves last remainder', () {
    e.reset(ClockConfig(limitsMs: [15000, 30000], equalLimits: false));
    e.start();
    now = 2000000;
    expect(e.press(1), false);
    e.press(0);
    expect(e.valueUs(0), 13000000);
    now += 5000000;
    e.press(1);
    expect(e.valueUs(1), 25000000);
    expect(e.valueUs(0), 15000000);
    expect(e.moves, [1, 1]);
    expect(e.lastMoveUs, [2000000, 5000000]);
  });
  test('total reserves do not reset and paused intervals are excluded', () {
    e.reset(ClockConfig(mode: ClockMode.total));
    e.start();
    now = 3000000;
    e.press(0);
    now += 4000000;
    e.press(1);
    expect(e.valueUs(0), 27000000);
    now += 2000000;
    e.pause();
    final frozen = e.valueUs(0);
    now += 100000000;
    expect(e.valueUs(0), frozen);
    e.resume();
    now += 1000000;
    e.press(0);
    expect(e.valueUs(0), 24000000);
    expect(e.lastMoveUs[0], 3000000);
  });
  test('stopwatch has no expiration and preserves last move', () {
    e.reset(ClockConfig(mode: ClockMode.stopwatch));
    e.start();
    now = 3600000000;
    expect(e.tick(), false);
    e.pause();
    now += 3000000;
    e.resume();
    now += 2000000;
    e.press(0);
    expect(e.valueUs(0), 3602000000);
    expect(e.valueUs(1), 0);
    now += 900000;
    e.press(1);
    expect(e.valueUs(0), 0);
    expect(e.valueUs(1), 900000);
    expect(e.expiredPlayer, null);
  });
  test('expiration wins a touch at deadline even without a frame', () {
    e.start();
    now = 30000000;
    e.press(0);
    expect(e.phase, GamePhase.finished);
    expect(e.moves, [0, 0]);
    expect(e.valueUs(0), 0);
    expect(e.valueUs(1), 30000000);
    expect(e.expiredPlayer, 0);
    expect(e.tick(), false);
    expect(e.press(0), false);
  });
  test('delayed frames never accumulate error; expiration clamps', () {
    e.start();
    now = 12345678;
    expect(e.valueUs(0), 17654322);
    now = 90000000;
    e.tick();
    expect(e.valueUs(0), 0);
  });
  test('pause at deadline finishes and reset creates a new session', () {
    e.start();
    now = 30000000;
    e.pause();
    expect(e.phase, GamePhase.finished);
    final session = e.session;
    e.reset();
    expect(e.session, session + 1);
    expect(e.moves, [0, 0]);
    expect(e.expiredPlayer, null);
    expect(e.phase, GamePhase.ready);
  });
  test('snapshot resumes only explicitly, ignoring wall time and downtime', () {
    e.start();
    now = 1234567;
    final data = jsonDecode(jsonEncode(e.snapshot())) as Map<String, dynamic>;
    now += 100000000;
    final recovered = ClockEngine.restore(data, () => now);
    expect(recovered.phase, GamePhase.paused);
    expect(recovered.valueUs(0), 28765433);
    recovered.resume();
    now += 1000000;
    recovered.press(0);
    expect(recovered.lastMoveUs[0], 2234567);
  });
  test('validation rejects invalid durations and snapshot states', () {
    for (final n in [-1, 0, 999, 10800001]) {
      expect(() => ClockConfig(limitsMs: [n, n]), throwsFormatException);
    }
    expect(
      ClockConfig(limitsMs: [1000, 10800000], equalLimits: false).limitsMs[1],
      10800000,
    );
    final data = jsonDecode(jsonEncode(e.snapshot())) as Map<String, dynamic>;
    data['activePlayer'] = 4;
    expect(() => ClockEngine.restore(data, () => now), throwsFormatException);
  });
  test('contacts must all lift; quick new touch has no fixed delay', () {
    final gate = ContactGate();
    expect(gate.down(1), true);
    gate.accept();
    expect(gate.down(2), false);
    gate.up(1);
    expect(gate.down(3), false);
    gate.up(2);
    gate.up(3);
    expect(gate.down(4), true);
    gate.accept();
    gate.up(4);
    expect(gate.down(5), true);
  });
  test('digital boundaries and no negative display', () {
    expect(formatClock(0), '00:00');
    expect(formatClock(-1), '00:00');
    expect(formatClock(1), '00:00.1');
    expect(formatClock(9900000), '00:09.9');
    expect(formatClock(10000000), '00:10');
    expect(formatClock(3600000000), '1:00:00');
    expect(formatClock(1500000, countdown: false), '00:01');
  });
  test('30 minute simulated session has no cumulative timing drift', () {
    e.reset(ClockConfig(mode: ClockMode.total, limitsMs: [10800000, 10800000]));
    e.start();
    final random = Random(42);
    final consumed = [0, 0];
    while (now < 1800000000) {
      final delta = min(1800000000 - now, random.nextInt(2000000) + 1);
      consumed[e.activePlayer] += delta;
      now += delta;
      e.press(e.activePlayer);
    }
    expect(e.valueUs(0), 10800000000 - consumed[0]);
    expect(e.valueUs(1), 10800000000 - consumed[1]);
  });
}
