import 'package:shared_preferences/shared_preferences.dart';

/// Player preferences that outlive a single game, kept on the device.
class GameSettings {
  const GameSettings(this._preferences);

  static const _mutedKey = 'settings.muted';

  final SharedPreferences _preferences;

  /// Loads the store. Call once during start up.
  static Future<GameSettings> load() async {
    return GameSettings(await SharedPreferences.getInstance());
  }

  /// Whether the player has silenced the app. Defaults to sound on.
  bool get isMuted => _preferences.getBool(_mutedKey) ?? false;

  Future<void> setMuted({required bool isMuted}) =>
      _preferences.setBool(_mutedKey, isMuted);
}
