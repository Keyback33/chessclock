import 'package:chessclock/platform/android_services.dart';

class FakeDevice implements DeviceServices {
  int alarms = 0;
  int silences = 0;
  bool awake = false;
  @override
  Future<String> privateDirectory() async => '';
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
