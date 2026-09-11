import 'dart:io';
import 'package:flutter/material.dart';
import 'app.dart';
import 'controllers/game_controller.dart';
import 'domain/clock.dart';
import 'platform/android_services.dart';
import 'storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final device = AndroidServices();
  final stopwatch = Stopwatch()..start();
  LocalStore? store;
  StoredState saved = StoredState(ClockConfig(), null);
  String? notice;
  try {
    store = LocalStore(Directory(await device.privateDirectory()));
    saved = await store.read();
    if (saved.corrupt)
      notice =
          'Los datos guardados no eran válidos. Se restauró la configuración inicial.';
  } catch (_) {
    notice = 'Almacenamiento no disponible. Esta sesión no se podrá recuperar.';
  }
  runApp(
    ChessClockApp(
      controller: GameController(
        engine: ClockEngine(saved.config, () => stopwatch.elapsedMicroseconds),
        device: device,
        store: store,
        recovery: saved.game,
        notice: notice,
      ),
    ),
  );
}
