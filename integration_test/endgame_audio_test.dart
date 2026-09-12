import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chessclock/platform/android_services.dart';
import '../test/support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'all five MP3s play to completion and pending playback can be cancelled',
    (tester) async {
      final device = AndroidServices(random: SequenceRandom());
      addTearDown(device.silence);
      for (var i = 0; i < 5; i++) {
        // Native alarm resolves on completion and throws on decoder/load errors.
        await device
            .alarm(sound: true, vibration: false)
            .timeout(const Duration(seconds: 30));
      }
      final cancelled = device.alarm(sound: true, vibration: false);
      await device.silence();
      await cancelled.timeout(const Duration(seconds: 5));
      final replaced = device.alarm(sound: true, vibration: false);
      final replacement = device.alarm(sound: true, vibration: false);
      await replaced.timeout(const Duration(seconds: 5));
      await device.silence();
      await replacement.timeout(const Duration(seconds: 5));
      await device
          .alarm(sound: false, vibration: true)
          .timeout(const Duration(seconds: 5));
      await expectLater(
        AndroidServices.channel.invokeMethod<void>('alarm', {
          'sound': true,
          'vibration': false,
          'asset': 'assets/audio/missing.mp3',
        }),
        throwsA(isA<Exception>()),
      );
    },
  );
}
