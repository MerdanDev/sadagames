import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:sadagames/games/games.dart';
import 'package:sadagames/menu/menu.dart';

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
}
