import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/app.dart';
import 'package:chessclock/controllers/game_controller.dart';
import 'package:chessclock/domain/clock.dart';
import 'package:chessclock/platform/android_services.dart';
import 'package:chessclock/storage/local_store.dart';
import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('orientation survives config copies and 1.0.0 JSON migrates', () {
    final old = ClockConfig().toJson()..remove('orientation');
    expect(ClockConfig.fromJson(old).orientation, ClockOrientation.automatic);
    for (final orientation in ClockOrientation.values) {
      final config = ClockConfig().withOrientation(orientation);
      expect(ClockConfig.fromJson(config.toJson()).orientation, orientation);
      expect(
        config.withAudio(sound: false, vibration: false).orientation,
        orientation,
      );
    }
  });

  test(
    'orientation persisted alongside active snapshot; old snapshot recovers',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chessclock-orientation-',
      );
      try {
        final store = LocalStore(directory);
        final engine = ClockEngine(
          ClockConfig(orientation: ClockOrientation.landscape),
          () => 0,
        )..start();
        await store.save(engine.config, engine.snapshot());
        final saved = await store.read();
        expect(saved.config.orientation, ClockOrientation.landscape);
        expect(
          ClockEngine.restore(saved.game!, () => 0).config.orientation,
          ClockOrientation.landscape,
        );
        final oldSnapshot =
            jsonDecode(jsonEncode(engine.snapshot())) as Map<String, dynamic>;
        (oldSnapshot['config'] as Map).remove('orientation');
        expect(
          ClockEngine.restore(oldSnapshot, () => 0).phase,
          GamePhase.paused,
        );
        expect(
          ClockEngine.restore(oldSnapshot, () => 0).config.orientation,
          ClockOrientation.automatic,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'Android channel sends all three explicit orientation policies',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidServices.channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AndroidServices.channel, null),
      );
      final device = AndroidServices();
      for (final orientation in ClockOrientation.values) {
        await device.setOrientation(orientation);
      }
      expect(calls.map((call) => call.method), everyElement('orientation'));
      expect(calls.map((call) => call.arguments), [
        'automatic',
        'portrait',
        'landscape',
      ]);
    },
  );

  testWidgets(
    'manual orientation never changes balances, phase, session or contact latch',
    (tester) async {
      var now = 0;
      final device = FakeDevice();
      final c = GameController(
        engine: ClockEngine(ClockConfig(), () => now),
        device: device,
      );
      expect(device.orientations, [ClockOrientation.automatic]);
      c.start();
      now = 2000000;
      c.pointerDown(1, 0);
      final session = c.engine.session;
      c.setOrientation(ClockOrientation.landscape);
      c.pointerDown(2, 1);
      expect(c.engine.phase, GamePhase.running);
      expect(c.engine.activePlayer, 1);
      expect(c.engine.moves, [1, 0]);
      expect(c.engine.valueUs(0), 28000000);
      expect(c.engine.session, session);
      now += 3000000;
      c.pause();
      final frozen = c.engine.snapshot();
      c.setOrientation(ClockOrientation.portrait);
      now += 10000000;
      expect(c.engine.valueUs(1), 27000000);
      expect(c.engine.snapshot()['valuesUs'], frozen['valuesUs']);
      c.audio(false, true);
      expect(c.engine.config.orientation, ClockOrientation.portrait);
      c.resume();
      expect(c.engine.activePlayer, 1);
      c.reset();
      expect(c.engine.config.orientation, ClockOrientation.portrait);
      expect(device.orientations, [
        ClockOrientation.automatic,
        ClockOrientation.landscape,
        ClockOrientation.portrait,
      ]);
      c.dispose();
    },
  );

  testWidgets(
    'automatic resize preserves running game and rotates entire panels',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var now = 0;
      final c = GameController(
        engine: ClockEngine(ClockConfig(), () => now),
        device: FakeDevice(),
      );
      await tester.pumpWidget(ChessClockApp(controller: c));
      c.start();
      now = 1000000;
      c.press(0);
      await tester.pump();
      expect(_turns(tester), [2, 0]);
      tester.view.physicalSize = const Size(892, 412);
      await tester.pump();
      expect(_turns(tester), [1, 3]);
      expect(c.engine.phase, GamePhase.running);
      expect(c.engine.activePlayer, 1);
      expect(c.engine.moves, [1, 0]);
      expect(c.engine.valueUs(0), 29000000);
      await tester.tap(find.byKey(const ValueKey('panel-1')));
      await tester.pump();
      expect(c.engine.moves, [1, 1]);
      tester.view.physicalSize = const Size(412, 892);
      await tester.pump();
      expect(_turns(tester), [2, 0]);
      expect(c.engine.moves, [1, 1]);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'orientation is available during pause without resetting the game',
    (tester) async {
      final device = FakeDevice();
      final c = GameController(
        engine: ClockEngine(ClockConfig(), () => 0),
        device: device,
      );
      await tester.pumpWidget(ChessClockApp(controller: c));
      c.start();
      c.press(0);
      c.pause();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('settings')));
      await tester.pumpAndSettle();
      expect(find.text('Configuración'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('orientation-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Horizontal').last);
      await tester.pumpAndSettle();
      expect(c.engine.config.orientation, ClockOrientation.landscape);
      expect(device.orientations.last, ClockOrientation.landscape);
      expect(c.engine.phase, GamePhase.paused);
      expect(c.engine.moves, [1, 0]);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(c.engine.config.orientation, ClockOrientation.landscape);
      await tester.tap(find.byKey(const ValueKey('resume')));
      await tester.pump();
      expect(c.engine.activePlayer, 1);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  for (final size in [const Size(800, 1280), const Size(1280, 800)]) {
    for (final orientation in [
      ClockOrientation.portrait,
      ClockOrientation.landscape,
    ]) {
      testWidgets(
        'manual layout survives Android large window restriction: $size $orientation',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final c = GameController(
            engine: ClockEngine(ClockConfig(orientation: orientation), () => 0),
            device: FakeDevice(),
          );
          await tester.pumpWidget(ChessClockApp(controller: c));
          await tester.pumpAndSettle();
          expect(
            _turns(tester),
            orientation == ClockOrientation.landscape ? [1, 3] : [2, 0],
          );
          expect(tester.takeException(), null);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        },
      );
    }
  }
}

List<int> _turns(WidgetTester tester) => [
  for (final player in [1, 0])
    tester
        .widget<RotatedBox>(find.byKey(ValueKey('player-orientation-$player')))
        .quarterTurns,
];
