import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/l10n/l10n.dart';
import 'package:sadagames/loading/loading.dart';
import 'package:sadagames/progress/progress.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Builds settings backed by in-memory preferences.
///
/// Pass `isMuted: true` to start from a muted app.
Future<GameSettings> createTestSettings({bool isMuted = false}) async {
  SharedPreferences.setMockInitialValues({'settings.muted': isMuted});
  return GameSettings(await SharedPreferences.getInstance());
}

/// Builds a progress store backed by in-memory preferences.
Future<GameProgress> createTestProgress() async {
  SharedPreferences.setMockInitialValues({});
  return GameProgress(await SharedPreferences.getInstance());
}

/// Builds a records store backed by in-memory preferences.
///
/// Pass [initialValues] keyed like `record.<gameId>.<metric>` to start from an
/// existing personal best.
Future<GameRecords> createTestRecords([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return GameRecords(await SharedPreferences.getInstance());
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    MockNavigator? navigator,
    PreloadCubit? preloadCubit,
    AudioCubit? audioCubit,
    GameRecords? records,
    GameSettings? settings,
    GameSounds? sounds,
    GameProgress? progress,
  }) async {
    final gameRecords = records ?? await createTestRecords();
    // Reuses whatever preferences the records store already set up.
    final gameSettings =
        settings ?? GameSettings(await SharedPreferences.getInstance());

    return pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<GameRecords>.value(value: gameRecords),
          RepositoryProvider<GameSettings>.value(value: gameSettings),
          RepositoryProvider<GameSounds>.value(
            value: sounds ?? createTestSounds(),
          ),
          RepositoryProvider<GameProgress>.value(
            value:
                progress ?? GameProgress(await SharedPreferences.getInstance()),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: preloadCubit ?? MockPreloadCubit()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: navigator != null
                ? MockNavigatorProvider(navigator: navigator, child: widget)
                : widget,
          ),
        ),
      ),
    );
  }
}
