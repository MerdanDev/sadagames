import 'package:sadagames/audio/audio.dart';

/// Sounds that record what they were asked to play instead of making noise.
///
/// The real engine needs a native library, so tests always use these.
SilentGameSounds createTestSounds() => SilentGameSounds();
