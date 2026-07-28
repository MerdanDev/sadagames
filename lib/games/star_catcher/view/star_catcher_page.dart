import 'package:flame/game.dart' hide Route;
import 'package:flutter/material.dart';
import 'package:sadagames/games/star_catcher/star_catcher.dart';

class StarCatcherPage extends StatelessWidget {
  const StarCatcherPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const StarCatcherPage());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: StarCatcherView()));
  }
}

class StarCatcherView extends StatefulWidget {
  const StarCatcherView({super.key, this.game});

  final StarCatcherGame? game;

  @override
  State<StarCatcherView> createState() => _StarCatcherViewState();
}

class _StarCatcherViewState extends State<StarCatcherView> {
  late final StarCatcherGame _game = widget.game ?? StarCatcherGame();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GameWidget(
            game: _game,
            overlayBuilderMap: {
              StarCatcherGame.gameOverOverlayId: (_, StarCatcherGame game) =>
                  _GameOverOverlay(game: game),
            },
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final StarCatcherGame game;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game over',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You caught ${game.score} stars',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: game.restart,
              child: const Text('Play again'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Back to games',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
