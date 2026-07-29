import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// An interrupted run, kept on the device so it can be picked back up.
///
/// Only games without a clock save anything. Restoring someone into the middle
/// of a falling star is worse than a fresh start, and those runs are short by
/// design anyway.
class GameProgress {
  const GameProgress(this._preferences);

  static const _prefix = 'progress.';

  final SharedPreferences _preferences;

  /// Loads the store. Call once during start up.
  static Future<GameProgress> load() async {
    return GameProgress(await SharedPreferences.getInstance());
  }

  static String _key(String gameId) => '$_prefix$gameId';

  /// The saved run for [gameId], or `null` if there is nothing to resume.
  ///
  /// A snapshot that cannot be read is treated as absent: a saved run is never
  /// worth crashing over, and the player simply gets a fresh board.
  Map<String, dynamic>? read(String gameId) {
    final stored = _preferences.getString(_key(gameId));
    if (stored == null) return null;
    try {
      final decoded = jsonDecode(stored);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Saves [snapshot] as the run to resume for [gameId].
  Future<void> save(String gameId, Map<String, dynamic> snapshot) =>
      _preferences.setString(_key(gameId), jsonEncode(snapshot));

  /// Forgets the saved run, once it is finished or abandoned.
  Future<void> clear(String gameId) => _preferences.remove(_key(gameId));
}
