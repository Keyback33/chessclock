import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chessclock/app.dart';
import 'package:chessclock/controllers/game_controller.dart';
import 'package:chessclock/domain/clock.dart';
import 'package:chessclock/platform/android_services.dart';
import 'package:chessclock/storage/local_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: private storage, all modes, touch, pause, alarm and restore',
    (tester) async {
      final device = AndroidServices();
      await device
          .moveClick(); // The channel must be available, even during preload.
      final path = await device.privateDirectory();
      expect(path, contains('no_backup'));
      final store = LocalStore(Directory('$path/integration-validation'));
      final watch = Stopwatch()..start();
      final c = GameController(
        engine: ClockEngine(
          ClockConfig(limitsMs: [30000, 45000], equalLimits: false),
          () => watch.elapsedMicroseconds,
        ),
        device: device,
        store: store,
      );
      await tester.pumpWidget(ChessClockApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('panel-0')));
      await tester.pump();
      expect(c.engine.activePlayer, 1);
      expect(c.engine.moves, [1, 0]);
      expect(c.notice, isNull);
      await tester.tap(find.byKey(const ValueKey('pause')));
      await tester.pumpAndSettle();
      final frozen = c.engine.valueUs(1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.engine.valueUs(1), frozen);
      await store.flush();
      final saved = await store.read();
      expect(saved.config.equalLimits, false);
      expect(
        ClockEngine.restore(saved.game!, () => watch.elapsedMicroseconds).phase,
        GamePhase.paused,
      );
      await tester.tap(find.byKey(const ValueKey('resume')));
      await tester.pump();
      expect(c.engine.phase, GamePhase.running);
      c.pause();
      c.reset();
      c.configure(ClockConfig(limitsMs: [1000, 1000], firstPlayer: 1));
      c.start();
      await tester.pump(const Duration(seconds: 2));
      c.frame();
      await tester.pump();
      expect(c.engine.phase, GamePhase.finished);
      expect(c.engine.valueUs(1), 0);
      await device.silence();
      for (final mode in [ClockMode.total, ClockMode.stopwatch]) {
        c.reset();
        c.configure(ClockConfig(mode: mode));
        c.start();
        await tester.pump(const Duration(milliseconds: 200));
        c.press(0);
        c.pause();
        await tester.pumpAndSettle();
        expect(c.engine.moves, [1, 0]);
        expect(c.engine.phase, GamePhase.paused);
      }
      await device.alarm(sound: true, vibration: true);
      await device.silence();
      c.reset();
      await store.flush();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
