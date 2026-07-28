import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/l10n/l10n.dart';
import 'package:sadagames/loading/loading.dart';
import 'package:sadagames/records/records.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

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
  }) async {
    final gameRecords = records ?? await createTestRecords();

    return pumpWidget(
      RepositoryProvider<GameRecords>.value(
        value: gameRecords,
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
