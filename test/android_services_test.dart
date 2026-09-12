import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/platform/android_services.dart';
import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('each alarm selects exactly one of the five endgame clips', () async {
    final calls = <MethodCall>[];
    final random = SequenceRandom();
    final device = AndroidServices(random: random);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidServices.channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidServices.channel, null),
    );
    for (var i = 1; i <= 5; i++) {
      await device.alarm(sound: true, vibration: false);
      expect(calls.last.method, 'alarm');
      expect(calls.last.arguments, {
        'sound': true,
        'vibration': false,
        'asset': 'assets/audio/endgame_$i.mp3',
      });
    }
    expect(calls, hasLength(5));
    expect(random.draws, 5);
    await device.alarm(sound: false, vibration: true);
    expect(calls.last.arguments, {'sound': false, 'vibration': true});
    expect(random.draws, 5);
  });

  test('mechanical click is forwarded once to the native channel', () async {
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
    await AndroidServices().moveClick();
    expect(calls.single.method, 'moveClick');
    expect(calls.single.arguments, isNull);
  });
}
