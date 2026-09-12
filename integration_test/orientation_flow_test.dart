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
    'native manual rotation, opposed panels, persistence and paused game',
    (tester) async {
      final device = AndroidServices();
      final store = LocalStore(
        Directory('${await device.privateDirectory()}/orientation-test'),
      );
      final watch = Stopwatch()..start();
      final c = GameController(
        engine: ClockEngine(
          ClockConfig(
            mode: ClockMode.stopwatch,
            orientation: ClockOrientation.portrait,
          ),
          () => watch.elapsedMicroseconds,
        ),
        device: device,
        store: store,
      );
      await tester.pumpWidget(ChessClockApp(controller: c));
      await tester.pumpAndSettle();
      await waitForOrientation(tester, landscape: false);
      c.start();
      c.press(0);
      c.pause();
      await tester.pumpAndSettle();
      final frozen = c.engine.valueUs(0);
      await tester.tap(find.byKey(const ValueKey('settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('orientation-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Horizontal').last);
      await tester.pumpAndSettle();
      await waitForOrientation(tester, landscape: true);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RotatedBox>(
              find.byKey(const ValueKey('player-orientation-1')),
            )
            .quarterTurns,
        2,
      );
      expect(
        tester
            .widget<RotatedBox>(
              find.byKey(const ValueKey('player-orientation-0')),
            )
            .quarterTurns,
        0,
      );
      for (final player in [0, 1]) {
        for (final element in ['time', 'dial']) {
          final box = tester.renderObject<RenderBox>(
            find.byKey(ValueKey('$element-$player')),
          );
          final axis =
              box.localToGlobal(const Offset(10, 0)) -
              box.localToGlobal(Offset.zero);
          expect(axis.dy, closeTo(0, 0.001));
          expect(axis.dx * (player == 0 ? 1 : -1), greaterThan(0));
        }
      }
      expect(c.engine.phase, GamePhase.paused);
      expect(c.engine.activePlayer, 1);
      expect(c.engine.valueUs(0), frozen);
      expect(c.engine.moves, [1, 0]);
      await store.flush();
      expect(
        (await store.read()).config.orientation,
        ClockOrientation.landscape,
      );
      c.resume();
      await tester.pump(const Duration(milliseconds: 100));
      c.setOrientation(ClockOrientation.portrait);
      await waitForOrientation(tester, landscape: false);
      expect(c.engine.phase, GamePhase.running);
      expect(c.engine.moves, [1, 0]);
      c.pause();
      c.setOrientation(ClockOrientation.automatic);
      await tester.pumpAndSettle();
      await store.flush();
      expect(
        (await store.read()).config.orientation,
        ClockOrientation.automatic,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}

Future<void> waitForOrientation(
  WidgetTester tester, {
  required bool landscape,
}) async {
  final deadline = Stopwatch()..start();
  while ((tester.view.physicalSize.width > tester.view.physicalSize.height) !=
          landscape &&
      deadline.elapsed < const Duration(seconds: 20)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(
    tester.view.physicalSize.width > tester.view.physicalSize.height,
    landscape,
  );
  await tester.pump(const Duration(milliseconds: 250));
}
