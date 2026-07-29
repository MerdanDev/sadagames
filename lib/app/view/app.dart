import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/l10n/l10n.dart';
import 'package:sadagames/loading/loading.dart';
import 'package:sadagames/progress/progress.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class App extends StatelessWidget {
  const App({
    required this.records,
    required this.settings,
    required this.sounds,
    required this.progress,
    required this.ads,
    super.key,
  });

  /// Personal bests, loaded before the app starts.
  final GameRecords records;

  /// Player preferences, loaded before the app starts.
  final GameSettings settings;

  /// The sound engine, shared by every game.
  final GameSounds sounds;

  /// Interrupted runs, so a long game can be picked back up.
  final GameProgress progress;

  /// The ads shown around the games. Still starting up when the app builds.
  final GameAds ads;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: records),
        RepositoryProvider.value(value: settings),
        RepositoryProvider.value(value: sounds),
        RepositoryProvider.value(value: progress),
        RepositoryProvider.value(value: ads),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) {
              final cubit = PreloadCubit(Images(prefix: ''));
              unawaited(cubit.loadSequentially());
              return cubit;
            },
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2A48DF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A48DF),
          foregroundColor: Color(0xFFFFFFFF),
        ),
        colorScheme: ColorScheme.fromSwatch(
          accentColor: const Color(0xFF2A48DF),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF2A48DF)),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoadingPage(),
    );
  }
}
