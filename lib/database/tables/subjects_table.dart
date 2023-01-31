import 'package:moor_flutter/moor_flutter.dart';

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get updatedAt => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();
  IntColumn get createdAt => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();
}
