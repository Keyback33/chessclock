import 'package:flutter/services.dart';
import '../domain/clock.dart';

abstract class DeviceServices {
  Future<String> privateDirectory();
  Future<void> keepAwake(bool enabled);
  Future<void> moveClick();
  Future<void> alarm({required bool sound, required bool vibration});
  Future<void> silence();
  Future<void> setOrientation(ClockOrientation orientation);
}

class AndroidServices implements DeviceServices {
  static const channel = MethodChannel('ar.com.chessclock/device');
  @override
  Future<String> privateDirectory() async =>
      (await channel.invokeMethod<String>('privateDirectory'))!;
  @override
  Future<void> keepAwake(bool enabled) =>
      channel.invokeMethod('keepAwake', enabled);
  @override
  Future<void> moveClick() => channel.invokeMethod('moveClick');
  @override
  Future<void> alarm({required bool sound, required bool vibration}) =>
      channel.invokeMethod('alarm', {'sound': sound, 'vibration': vibration});
  @override
  Future<void> silence() => channel.invokeMethod('silence');
  @override
  Future<void> setOrientation(ClockOrientation orientation) =>
      channel.invokeMethod('orientation', orientation.name);
}
