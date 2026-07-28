import 'package:audioplayers/audioplayers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadagames/audio/audio.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

/// Builds sounds backed by a mocked player, so tests never touch real audio.
///
/// Registers its own mocktail fallbacks, so suites do not have to.
///
/// Pass an [audioPlayer] to verify what a game asked the player to do; sounds
/// start with `resume`.
GameSounds createTestSounds([MockAudioPlayer? audioPlayer]) {
  registerFallbackValue(AssetSource('effect.mp3'));
  registerFallbackValue(Duration.zero);

  final player = audioPlayer ?? MockAudioPlayer();
  when(() => player.setSource(any())).thenAnswer((_) async {});
  when(() => player.seek(any())).thenAnswer((_) async {});
  when(player.resume).thenAnswer((_) async {});
  when(player.stop).thenAnswer((_) async {});
  when(() => player.setPlaybackRate(any())).thenAnswer((_) async {});
  when(() => player.play(any())).thenAnswer((_) async {});
  return GameSounds(player);
}
