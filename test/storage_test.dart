import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessclock/domain/clock.dart';
import 'package:chessclock/storage/local_store.dart';

void main() {
  test(
    'atomic queued writes persist latest preferences and snapshot',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chessclock-test-',
      );
      try {
        final store = LocalStore(directory);
        final config = ClockConfig(firstPlayer: 1);
        final e = ClockEngine(config, () => 0)..start();
        final one = store.save(ClockConfig(), null);
        final two = store.save(config, e.snapshot());
        await Future.wait([one, two]);
        final saved = await store.read();
        expect(saved.config.firstPlayer, 1);
        expect(saved.game!['phase'], 'running');
        expect(
          ClockEngine.restore(saved.game!, () => 0).phase,
          GamePhase.paused,
        );
        expect(
          await File('${directory.path}/chessclock.json.tmp').exists(),
          false,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  test('invalid JSON and schema recover safely', () async {
    final directory = await Directory.systemTemp.createTemp('chessclock-test-');
    try {
      final store = LocalStore(directory);
      expect((await store.read()).corrupt, false);
      for (final content in [
        '{broken',
        '{"schema":2}',
        '{"schema":1,"config":{}}',
      ]) {
        await File('${directory.path}/chessclock.json').writeAsString(content);
        final saved = await store.read();
        expect(saved.corrupt, true);
        expect(saved.game, null);
        expect(saved.config.limitsMs, [30000, 30000]);
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
