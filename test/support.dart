import 'package:chessclock/platform/android_services.dart';
import 'package:chessclock/domain/clock.dart';

class FakeDevice implements DeviceServices {
  int alarms = 0;
  int clicks = 0;
  bool failClick = false;
  int silences = 0;
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
  }

  @override
  Future<void> silence() async {
    silences++;
  }
}
