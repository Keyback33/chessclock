import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/platform/android_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
