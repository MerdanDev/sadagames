import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/app/app.dart';

import '../../helpers/helpers.dart';

void main() {
  group('App', () {
    testWidgets('renders AppView', (tester) async {
      await tester.pumpWidget(
        App(
          records: await createTestRecords(),
          settings: await createTestSettings(),
          sounds: createTestSounds(),
          progress: await createTestProgress(),
          ads: NoGameAds(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 400));
      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
