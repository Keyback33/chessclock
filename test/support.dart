import 'dart:math';
import 'package:chessclock/platform/android_services.dart';
import 'package:chessclock/domain/clock.dart';

class FakeDevice implements DeviceServices {
  int alarms = 0;
  int clicks = 0;
  bool failClick = false;
  int silences = 0;
  final List<String> events = [];
  final List<({bool sound, bool vibration})> alarmOptions = [];
  bool awake = false;
  final List<ClockOrientation> orientations = [];
  @override
  Future<void> setOrientation(ClockOrientation orientation) async {
    orientations.add(orientation);
  }

  @override
  Future<String> privateDirectory() async => '';
  @override
  Future<void> moveClick() async {
    clicks++;
    if (failClick) throw StateError('Audio unavailable');
  }

  @override
  Future<void> keepAwake(bool enabled) async {
    awake = enabled;
  }

  @override
  Future<void> alarm({required bool sound, required bool vibration}) async {
    alarms++;
    events.add('alarm');
    alarmOptions.add((sound: sound, vibration: vibration));
  }

  @override
  Future<void> silence() async {
    silences++;
    events.add('silence');
  }
}

class SequenceRandom implements Random {
  int draws = 0;
  @override
  int nextInt(int max) => draws++ % max;
  @override
  bool nextBool() => throw UnsupportedError('Only integer draws are expected');
  @override
  double nextDouble() =>
      throw UnsupportedError('Only integer draws are expected');
}
