import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/app/app.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/bootstrap.dart';
import 'package:sadagames/progress/progress.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

Future<void> main() async {
  await bootstrap(
    () async => App(
      records: await GameRecords.load(),
      settings: await GameSettings.load(),
      sounds: await _startSounds(),
      progress: await GameProgress.load(),
      // Test units: showing yourself a live ad is invalid traffic.
      ads: startAds(isLive: false),
    ),
  );
}

/// Brings the sound engine up. A failure leaves the app silent, never broken.
Future<GameSounds> _startSounds() async {
  final sounds = SoLoudGameSounds();
  await sounds.init();
  return sounds.isReady ? sounds : SilentGameSounds();
}
