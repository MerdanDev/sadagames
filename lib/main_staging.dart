import 'package:sadagames/app/app.dart';
import 'package:sadagames/bootstrap.dart';
import 'package:sadagames/records/records.dart';

Future<void> main() async {
  await bootstrap(() async => App(records: await GameRecords.load()));
}
