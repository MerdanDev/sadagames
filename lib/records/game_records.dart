import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Formats a record with its unit, pluralising regular unit words.
String formatRecord(int value, String unit) =>
    '$value $unit${value == 1 ? '' : 's'}';

/// Which direction counts as an improvement for a record.
enum RecordGoal {
  /// A bigger number is better, like a score.
  higher,

  /// A smaller number is better, like a move count or a time.
  lower,
}

/// Personal bests, kept on the device between launches.
///
/// Records are stored per game and per metric, so a game can track more than
/// one ('moves' and 'seconds' for example).
class GameRecords {
  GameRecords(this._preferences);

  final SharedPreferences _preferences;

  /// Ticks whenever a record changes.
  ///
  /// Screens that display records listen to this so a new best shows up
  /// without them being rebuilt by hand. `GameRecords` itself stays a plain
  /// value, since `RepositoryProvider` rejects `Listenable` subtypes.
  final ValueNotifier<int> changes = ValueNotifier(0);

  /// Loads the store. Call once during start up.
  static Future<GameRecords> load() async {
    return GameRecords(await SharedPreferences.getInstance());
  }

  static String _key(String gameId, String metric) => 'record.$gameId.$metric';

  /// The current best for [metric], or `null` when the game has never ended.
  int? read(String gameId, String metric) =>
      _preferences.getInt(_key(gameId, metric));

  /// Whether [value] would beat the stored best.
  ///
  /// Synchronous, so a game can decide what to show the moment a run ends
  /// instead of waiting for the write. The first result always counts.
  bool beatsRecord(
    String gameId,
    String metric,
    int value, {
    required RecordGoal goal,
  }) {
    final current = read(gameId, metric);
    return current == null ||
        (goal == RecordGoal.higher ? value > current : value < current);
  }

  /// Stores [value] when it beats the current best.
  ///
  /// Returns whether it was a new record.
  Future<bool> submit(
    String gameId,
    String metric,
    int value, {
    required RecordGoal goal,
  }) async {
    final isRecord = beatsRecord(gameId, metric, value, goal: goal);
    if (isRecord) {
      await _preferences.setInt(_key(gameId, metric), value);
      changes.value++;
    }
    return isRecord;
  }
}
