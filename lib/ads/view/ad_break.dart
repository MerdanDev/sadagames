import 'package:flame/game.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/settings/settings.dart';

/// Runs [show] with the game frozen and the app silent, restoring both after.
///
/// A full screen ad covers the screen but does not take the audio session, so
/// without this the game keeps ticking and its notes play underneath the ad.
/// The mute is restored to whatever the player had chosen, never to "on" —
/// an ad that un-mutes a muted app is the sort of thing players uninstall for.
Future<T> duringAdBreak<T>({
  required GameSounds sounds,
  required Future<T> Function() show,
  GameSettings? settings,
  FlameGame? game,
}) async {
  game?.pauseEngine();
  sounds.setMuted(isMuted: true);
  try {
    return await show();
  } finally {
    sounds.setMuted(isMuted: settings?.isMuted ?? false);
    game?.resumeEngine();
  }
}
