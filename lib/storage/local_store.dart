import 'dart:convert';
import 'dart:io';
import '../domain/clock.dart';

class StoredState {
  final ClockConfig config;
  final Map<String, dynamic>? game;
  final bool corrupt;
  StoredState(this.config, this.game, {this.corrupt = false});
}

class LocalStore {
  final Directory directory;
  Future<void> _pending = Future.value();
  LocalStore(this.directory);
  File get _file => File('${directory.path}/chessclock.json');
  Future<StoredState> read() async {
    try {
      if (!await _file.exists()) return StoredState(ClockConfig(), null);
      final json =
          jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      if (json['schema'] != 1)
        throw const FormatException('Versión desconocida');
      final config = ClockConfig.fromJson(
        json['config'] as Map<String, dynamic>,
      );
      final game = json['game'] as Map<String, dynamic>?;
      if (game != null) ClockEngine.restore(game, () => 0);
      return StoredState(config, game);
    } catch (_) {
      return StoredState(ClockConfig(), null, corrupt: true);
    }
  }

  Future<void> save(ClockConfig config, Map<String, Object?>? game) {
    // Freeze values before awaiting; serialize writes to prevent stale replacement.
    final content = jsonEncode({
      'schema': 1,
      'config': config.toJson(),
      'game': game,
    });
    final next = _pending.then((_) async {
      await directory.create(recursive: true);
      final temp = File('${_file.path}.tmp');
      await temp.writeAsString(content, flush: true);
      await temp.rename(_file.path);
    });
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> flush() => _pending;
}
