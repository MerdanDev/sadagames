import 'package:sadagames/app/app.dart';
import 'package:sadagames/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
