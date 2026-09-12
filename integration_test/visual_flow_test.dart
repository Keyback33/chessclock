import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chessclock/app.dart';
import 'package:chessclock/controllers/game_controller.dart';
import 'package:chessclock/domain/clock.dart';
import 'package:chessclock/platform/android_services.dart';
import 'package:chessclock/ui/move_button.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('plungers, orientation and current README screenshots', (
    tester,
  ) async {
    var now = 0;
    final c = GameController(
      engine: ClockEngine(
        ClockConfig(
          mode: ClockMode.total,
          limitsMs: [600000, 600000],
          orientation: ClockOrientation.portrait,
        ),
        () => now,
      ),
      device: AndroidServices(),
    );
    await tester.pumpWidget(ChessClockApp(controller: c));
    await tester.pumpAndSettle();
    await waitForAxis(tester, landscape: false);
    await precacheImage(
      const AssetImage(MoveButton.asset),
      tester.element(find.byType(ChessClockApp)),
    );
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    c.start();
    await tester.pump();
    now = 7000000;
    await tester.tap(find.byKey(const ValueKey('move-button-0')));
    await tester.pump();
    expect(c.engine.moves, [1, 0]);
    await settlePlungers(tester);
    now = 13000000;
    await tester.tap(find.byKey(const ValueKey('move-button-1')));
    await tester.pump();
    await settlePlungers(tester);
    expect(c.engine.moves, [1, 1]);
    expectPlungerFrame(tester, player: 0, frame: 0);
    expectPlungerFrame(tester, player: 1, frame: 33);
    expect(c.notice, isNull);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('relojes');
    c.setOrientation(ClockOrientation.landscape);
    await waitForAxis(tester, landscape: true);
    expect(c.engine.moves, [1, 1]);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('relojes-horizontal');
    c.pause();
    c.reset();
    c.setOrientation(ClockOrientation.portrait);
    await waitForAxis(tester, landscape: false);
    await tester.tap(find.byKey(const ValueKey('settings')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('configuracion');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}

Future<void> settlePlungers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 80));
  await tester.pump(const Duration(milliseconds: 200));
}

void expectPlungerFrame(
  WidgetTester tester, {
  required int player,
  required int frame,
}) {
  final button = find.byKey(ValueKey('move-button-$player'));
  final size = tester.getSize(button);
  final tileHeight = size.width * 250 / 296;
  final crop = (tileHeight - size.height) / 2;
  final transform = tester.widget<Transform>(
    find.descendant(of: button, matching: find.byType(Transform)),
  );
  final translation = transform.transform.getTranslation();
  expect(translation.x, closeTo(-(frame % 6) * size.width, .01));
  expect(translation.y, closeTo(-(frame ~/ 6) * tileHeight - crop, .01));
}

Future<void> waitForAxis(WidgetTester tester, {required bool landscape}) async {
  final watch = Stopwatch()..start();
  while ((tester.view.physicalSize.width > tester.view.physicalSize.height) !=
          landscape &&
      watch.elapsed < const Duration(seconds: 20)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(
    tester.view.physicalSize.width > tester.view.physicalSize.height,
    landscape,
  );
  await tester.pump(const Duration(milliseconds: 500));
}
