import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/app/app.dart';

import '../../helpers/helpers.dart';

void main() {
  group('App', () {
    testWidgets('renders AppView', (tester) async {
      await tester.pumpWidget(App(records: await createTestRecords()));

      await tester.pumpAndSettle(const Duration(seconds: 400));
      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
