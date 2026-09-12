import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/clock.dart';
import '../platform/android_services.dart';
import '../storage/local_store.dart';

class GameController extends ChangeNotifier {
  ClockEngine engine;
  final DeviceServices device;
  final LocalStore? store;
  final ContactGate contacts = ContactGate();
  Timer? _deadline;
  int _generation = 0;
  int? _alarmedSession;
  bool _disposed = false;
  String? notice;
  Map<String, dynamic>? recovery;
  GameController({
    required this.engine,
    required this.device,
    this.store,
    this.recovery,
    this.notice,
  }) {
    _run(device.setOrientation(engine.config.orientation));
  }
  void _run(Future<void> action) {
    unawaited(
      action.catchError((Object error) {
        if (!_disposed) {
          notice =
              'No se pudo completar una función del dispositivo o guardar los datos.';
          notifyListeners();
        }
      }),
    );
  }

  void _save() => _run(
    store?.save(
          engine.config,
          engine.phase == GamePhase.ready ? null : engine.snapshot(),
        ) ??
        Future.value(),
  );
  void _changed() {
    _generation++;
    _deadline?.cancel();
    if (engine.phase == GamePhase.running &&
        engine.config.mode != ClockMode.stopwatch)
      _scheduleRemaining(_generation);
    _run(device.keepAwake(engine.phase == GamePhase.running));
    if (engine.phase == GamePhase.finished &&
        _alarmedSession != engine.session) {
      _alarmedSession = engine.session;
      _run(
        device.alarm(
          sound: engine.config.sound,
          vibration: engine.config.vibration,
        ),
      );
    }
    _save();
    notifyListeners();
  }

  void _scheduleRemaining(int generation) {
    _deadline = Timer(
      Duration(microseconds: engine.valueUs(engine.activePlayer)),
      () {
        if (_disposed || generation != _generation) return;
        if (engine.tick()) {
          _changed();
        } else {
          _scheduleRemaining(generation);
        }
      },
    );
  }

  void frame() {
    if (engine.tick()) _changed();
  }

  void start() {
    if (engine.start()) _changed();
  }

  void press(int player) {
    _press(player);
  }

  bool _press(int player) {
    if (!engine.press(player)) return false;
    // press also returns true when it detects expiration: only click on a move.
    if (engine.phase == GamePhase.running && engine.config.sound) {
      _run(device.moveClick());
    }
    _changed();
    return true;
  }

  void pointerDown(int pointer, int? player) {
    if (contacts.down(pointer) &&
        player != null &&
        engine.phase == GamePhase.running &&
        player == engine.activePlayer) {
      if (_press(player)) {
        contacts.accept();
      }
    }
  }

  void pointerUp(int pointer) => contacts.up(pointer);
  void pause({bool interrupted = false}) {
    if (engine.pause(
      reason: interrupted ? 'Partida pausada por interrupción' : null,
    ))
      _changed();
    _run(device.silence());
  }

  void interrupt() {
    pause(interrupted: true);
    contacts.clear();
    _run(device.silence());
  }

  void resume() {
    if (engine.resume()) _changed();
  }

  void reset() {
    _run(device.silence());
    engine.reset();
    _alarmedSession = null;
    recovery = null;
    _changed();
  }

  void configure(ClockConfig config) {
    if (engine.phase != GamePhase.ready) return;
    if (engine.config.orientation != config.orientation) {
      _run(device.setOrientation(config.orientation));
    }
    engine.reset(config);
    _changed();
  }

  void audio(bool sound, bool vibration) {
    if (engine.phase == GamePhase.running) return;
    engine.config = engine.config.withAudio(sound: sound, vibration: vibration);
    _save();
    notifyListeners();
  }

  void setOrientation(ClockOrientation orientation) {
    if (orientation == engine.config.orientation) return;
    engine.config = engine.config.withOrientation(orientation);
    _run(device.setOrientation(orientation));
    // A display preference never resets a game, changes its turn or unlatches touches.
    _save();
    notifyListeners();
  }

  void testAlarm(bool sound, bool vibration) =>
      _run(device.alarm(sound: sound, vibration: vibration));
  void silence() => _run(device.silence());
  void recover() {
    if (recovery == null) return;
    final orientation = engine.config.orientation;
    engine = ClockEngine.restore(recovery!, engine.nowUs);
    engine.config = engine.config.withOrientation(orientation);
    recovery = null;
    _alarmedSession = engine.phase == GamePhase.finished
        ? engine.session
        : null;
    _changed();
  }

  void discardRecovery() {
    recovery = null;
    _save();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _deadline?.cancel();
    unawaited(device.silence().catchError((Object _) {}));
    unawaited(device.keepAwake(false).catchError((Object _) {}));
    super.dispose();
  }
}
