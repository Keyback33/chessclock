enum ClockMode { perMove, total, stopwatch }

enum GamePhase { ready, running, paused, finished }

class ClockConfig {
  final ClockMode mode;
  final List<int> limitsMs;
  final List<String> names;
  final int firstPlayer;
  final bool equalLimits;
  final bool sound;
  final bool vibration;
  ClockConfig({
    this.mode = ClockMode.perMove,
    List<int> limitsMs = const [30000, 30000],
    List<String> names = const ['Jugador 1', 'Jugador 2'],
    this.firstPlayer = 0,
    this.equalLimits = true,
    this.sound = true,
    this.vibration = true,
  }) : limitsMs = List.unmodifiable(limitsMs),
       names = List.unmodifiable(names) {
    if (limitsMs.length != 2 ||
        limitsMs.any((v) => v < 1000 || v > 10800000) ||
        names.length != 2 ||
        names.any((n) => n.trim().isEmpty || n.length > 24) ||
        firstPlayer < 0 ||
        firstPlayer > 1 ||
        (equalLimits && limitsMs[0] != limitsMs[1])) {
      throw const FormatException('Configuración inválida');
    }
  }
  ClockConfig withAudio({required bool sound, required bool vibration}) =>
      ClockConfig(
        mode: mode,
        limitsMs: limitsMs,
        names: names,
        firstPlayer: firstPlayer,
        equalLimits: equalLimits,
        sound: sound,
        vibration: vibration,
      );
  Map<String, Object> toJson() => {
    'mode': mode.name,
    'limitsMs': limitsMs,
    'names': names,
    'firstPlayer': firstPlayer,
    'equalLimits': equalLimits,
    'sound': sound,
    'vibration': vibration,
  };
  factory ClockConfig.fromJson(Map<String, dynamic> json) => ClockConfig(
    mode: ClockMode.values.byName(json['mode'] as String),
    limitsMs: (json['limitsMs'] as List).cast<int>(),
    names: (json['names'] as List).cast<String>(),
    firstPlayer: json['firstPlayer'] as int,
    equalLimits: json['equalLimits'] as bool,
    sound: json['sound'] as bool,
    vibration: json['vibration'] as bool,
  );
}

/// Pure Dart engine. Every transition captures one monotonic timestamp.
class ClockEngine {
  ClockConfig config;
  final int Function() nowUs;
  GamePhase phase = GamePhase.ready;
  late int activePlayer;
  late List<int> _valuesUs;
  List<int> moves = [0, 0];
  List<int> lastMoveUs = [0, 0];
  int _anchorUs = 0;
  int _turnUsedUs = 0;
  int? expiredPlayer;
  String? pauseReason;
  int revision = 0;
  int session = 0;
  ClockEngine(this.config, this.nowUs) {
    _initialize();
  }
  void _initialize() {
    activePlayer = config.firstPlayer;
    _valuesUs = config.mode == ClockMode.stopwatch
        ? [0, 0]
        : config.limitsMs.map((m) => m * 1000).toList();
  }

  int valueUs(int player, [int? at]) {
    if (phase != GamePhase.running || activePlayer != player)
      return _valuesUs[player];
    final elapsed = (at ?? nowUs()) - _anchorUs;
    return config.mode == ClockMode.stopwatch
        ? _valuesUs[player] + elapsed
        : (_valuesUs[player] - elapsed).clamp(0, _valuesUs[player]);
  }

  bool start() {
    if (phase != GamePhase.ready) return false;
    _anchorUs = nowUs();
    phase = GamePhase.running;
    revision++;
    return true;
  }

  bool _expire(int now) {
    if (phase != GamePhase.running ||
        config.mode == ClockMode.stopwatch ||
        valueUs(activePlayer, now) > 0)
      return false;
    _valuesUs[activePlayer] = 0;
    expiredPlayer = activePlayer;
    phase = GamePhase.finished;
    revision++;
    return true;
  }

  bool tick() => _expire(nowUs());
  bool press(int player) {
    if (phase != GamePhase.running) return false;
    final now = nowUs();
    if (_expire(now)) return true;
    if (player != activePlayer) return false;
    _valuesUs[player] = valueUs(player, now);
    lastMoveUs[player] = _turnUsedUs + now - _anchorUs;
    moves[player]++;
    activePlayer = 1 - player;
    if (config.mode != ClockMode.total) {
      _valuesUs[activePlayer] = config.mode == ClockMode.stopwatch
          ? 0
          : config.limitsMs[activePlayer] * 1000;
    }
    _turnUsedUs = 0;
    _anchorUs = now;
    revision++;
    return true;
  }

  bool pause({String? reason}) {
    if (phase != GamePhase.running) return false;
    final now = nowUs();
    if (_expire(now)) return true;
    _valuesUs[activePlayer] = valueUs(activePlayer, now);
    _turnUsedUs += now - _anchorUs;
    phase = GamePhase.paused;
    pauseReason = reason;
    revision++;
    return true;
  }

  bool resume() {
    if (phase != GamePhase.paused) return false;
    _anchorUs = nowUs();
    phase = GamePhase.running;
    pauseReason = null;
    revision++;
    return true;
  }

  void reset([ClockConfig? newConfig]) {
    config = newConfig ?? config;
    phase = GamePhase.ready;
    expiredPlayer = null;
    pauseReason = null;
    moves = [0, 0];
    lastMoveUs = [0, 0];
    _turnUsedUs = 0;
    session++;
    revision++;
    _initialize();
  }

  Map<String, Object?> snapshot() {
    final now = nowUs();
    return {
      'phase': phase.name,
      'config': config.toJson(),
      'activePlayer': activePlayer,
      'valuesUs': [valueUs(0, now), valueUs(1, now)],
      'moves': List<int>.of(moves),
      'lastMoveUs': List<int>.of(lastMoveUs),
      'expiredPlayer': expiredPlayer,
      'turnUsedUs':
          _turnUsedUs + (phase == GamePhase.running ? now - _anchorUs : 0),
    };
  }

  factory ClockEngine.restore(Map<String, dynamic> data, int Function() nowUs) {
    final e = ClockEngine(
      ClockConfig.fromJson(data['config'] as Map<String, dynamic>),
      nowUs,
    );
    final savedPhase = GamePhase.values.byName(data['phase'] as String);
    e.activePlayer = data['activePlayer'] as int;
    e._valuesUs = (data['valuesUs'] as List).cast<int>().toList();
    e.moves = (data['moves'] as List).cast<int>().toList();
    e.lastMoveUs = (data['lastMoveUs'] as List).cast<int>().toList();
    e._turnUsedUs = data['turnUsedUs'] as int;
    e.expiredPlayer = data['expiredPlayer'] as int?;
    if (e.activePlayer < 0 ||
        e.activePlayer > 1 ||
        e._valuesUs.length != 2 ||
        e.moves.length != 2 ||
        e.lastMoveUs.length != 2 ||
        e._turnUsedUs < 0 ||
        [...e._valuesUs, ...e.moves, ...e.lastMoveUs].any((v) => v < 0) ||
        (e.expiredPlayer != null &&
            (e.expiredPlayer! < 0 || e.expiredPlayer! > 1))) {
      throw const FormatException('Instantánea inválida');
    }
    for (var i = 0; i < 2; i++) {
      if (e.config.mode != ClockMode.stopwatch &&
          e._valuesUs[i] > e.config.limitsMs[i] * 1000) {
        throw const FormatException('Saldo inválido');
      }
    }
    if (savedPhase == GamePhase.finished) {
      if (e.config.mode == ClockMode.stopwatch ||
          e.expiredPlayer != e.activePlayer ||
          e._valuesUs[e.activePlayer] != 0) {
        throw const FormatException('Vencimiento inválido');
      }
    } else if (e.expiredPlayer != null ||
        (savedPhase != GamePhase.ready &&
            e.config.mode != ClockMode.stopwatch &&
            e._valuesUs[e.activePlayer] == 0)) {
      throw const FormatException('Estado inválido');
    }
    e.phase = savedPhase == GamePhase.running ? GamePhase.paused : savedPhase;
    if (e.phase == GamePhase.paused)
      e.pauseReason = 'Recuperada desde el último estado guardado';
    return e;
  }
}

/// No fixed debounce: the latch opens when all contacts have lifted.
class ContactGate {
  final Set<int> _pointers = {};
  bool _latched = false;
  bool down(int pointer) {
    _pointers.add(pointer);
    return !_latched;
  }

  void accept() {
    _latched = true;
  }

  void up(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.isEmpty) _latched = false;
  }

  void clear() {
    _pointers.clear();
    _latched = false;
  }
}

String formatClock(int us, {bool countdown = true}) {
  us = us < 0 ? 0 : us;
  if (us == 0) return '00:00';
  if (countdown && us < 10000000) {
    final tenths = (us / 100000).ceil();
    return '00:${(tenths ~/ 10).toString().padLeft(2, '0')}.${tenths % 10}';
  }
  final seconds = countdown ? (us / 1000000).ceil() : us ~/ 1000000;
  final mm = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
  final ss = (seconds % 60).toString().padLeft(2, '0');
  return seconds >= 3600 ? '${seconds ~/ 3600}:$mm:$ss' : '$mm:$ss';
}
