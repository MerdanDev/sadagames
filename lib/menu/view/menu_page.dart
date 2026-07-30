import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/games/games.dart';
import 'package:sadagames/l10n/l10n.dart';
import 'package:sadagames/records/records.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MenuPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuAppBarTitle)),
      // The banner is anchored below the list rather than pinned into it, so
      // it can never slide under the player's thumb mid-scroll.
      body: const SafeArea(
        child: Column(
          children: [
            Expanded(child: MenuView()),
            MenuBanner(),
          ],
        ),
      ),
    );
  }
}

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    // Records change while a game is open, so rebuild the list when one does.
    return ListenableBuilder(
      listenable: context.read<GameRecords>().changes,
      builder: (context, _) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: GameCatalog.entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return GameCatalogTile(entry: GameCatalog.entries[index]);
          },
        );
      },
    );
  }
}

/// A tappable card that launches the game it represents.
class GameCatalogTile extends StatelessWidget {
  const GameCatalogTile({required this.entry, super.key});

  final GameCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final metric = entry.recordMetric;
    final record = metric == null
        ? null
        : context.read<GameRecords>().read(entry.id, metric);

    return Card(
      key: Key('gameCatalogTile_${entry.id}'),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: entry.color,
          child: _TileBadge(entry: entry),
        ),
        title: Text(
          entry.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.description),
            if (record != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: Color(0xFFE0A500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Best: ${formatRecord(record, entry.recordUnit)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFE0A500),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push<void>(entry.routeBuilder()),
      ),
    );
  }
}

/// Whatever the entry uses to identify itself: an icon, or short text for a
/// game whose name is a number.
class _TileBadge extends StatelessWidget {
  const _TileBadge({required this.entry});

  final GameCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.icon;
    if (icon != null) return Icon(icon, color: Colors.white);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        child: Text(
          entry.iconLabel!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
