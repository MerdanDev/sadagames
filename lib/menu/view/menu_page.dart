import 'package:flutter/material.dart';
import 'package:sadagames/games/games.dart';
import 'package:sadagames/l10n/l10n.dart';

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
      body: const SafeArea(child: MenuView()),
    );
  }
}

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: GameCatalog.entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return GameCatalogTile(entry: GameCatalog.entries[index]);
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
          child: Icon(entry.icon, color: Colors.white),
        ),
        title: Text(
          entry.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(entry.description),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () =>
            Navigator.of(context).push<void>(entry.routeBuilder()),
      ),
    );
  }
}
