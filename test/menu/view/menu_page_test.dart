import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:sadagames/games/games.dart';
import 'package:sadagames/menu/menu.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

void main() {
  group('MenuPage', () {
    testWidgets('renders MenuView', (tester) async {
      await tester.pumpApp(const MenuPage());
      expect(find.byType(MenuView), findsOneWidget);
    });
  });

  group('MenuView', () {
    testWidgets('renders a tile for every catalog entry', (tester) async {
      // The list builds lazily, so give it a surface tall enough to hold every
      // entry at once rather than only the ones above the fold.
      tester.view
        ..physicalSize = const Size(1200, 4000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpApp(const MenuView());

      expect(
        find.byType(GameCatalogTile),
        findsNWidgets(GameCatalog.entries.length),
      );

      for (final entry in GameCatalog.entries) {
        expect(find.text(entry.name), findsOneWidget);
      }
    });

    testWidgets('pushes the game route when a tile is tapped', (tester) async {
      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(() => navigator.push<void>(any())).thenAnswer((_) async {});

      await tester.pumpApp(const MenuView(), navigator: navigator);

      final firstEntry = GameCatalog.entries.first;
      await tester.tap(find.byKey(Key('gameCatalogTile_${firstEntry.id}')));

      verify(() => navigator.push<void>(any())).called(1);
    });
  });

  group('records on the menu', () {
    testWidgets('are hidden until a game has been played', (tester) async {
      await tester.pumpApp(const MenuView());

      expect(find.textContaining('Best:'), findsNothing);
    });

    testWidgets('show the stored best for that game', (tester) async {
      await tester.pumpApp(
        const MenuView(),
        records: await createTestRecords({'record.star_catcher.score': 12}),
      );

      expect(find.text('Best: 12 stars'), findsOneWidget);
    });

    testWidgets('use the singular unit for a best of one', (tester) async {
      await tester.pumpApp(
        const MenuView(),
        records: await createTestRecords({'record.star_catcher.score': 1}),
      );

      expect(find.text('Best: 1 star'), findsOneWidget);
    });

    testWidgets('refresh when a record is set while the menu is alive', (
      tester,
    ) async {
      final records = await createTestRecords();
      await tester.pumpApp(const MenuView(), records: records);
      expect(find.textContaining('Best:'), findsNothing);

      await records.submit(
        'star_catcher',
        'score',
        8,
        goal: RecordGoal.higher,
      );
      await tester.pump();

      expect(find.text('Best: 8 stars'), findsOneWidget);
    });
  });
}
