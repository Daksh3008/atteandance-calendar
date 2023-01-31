import 'package:attendance_calendar/database/tables/attendance_table.dart';
import 'package:attendance_calendar/database/tables/subjects_table.dart';
import 'package:moor_flutter/moor_flutter.dart';

part 'database.g.dart';

///
/// Build command : flutter pub run build_runner build --delete-conflicting-outputs
/// Database code analyzer: flutter pub run moor_generator analyze
/// Identicy Database: flutter pub run moor_generator identify-databases
/// Export Database: pub run moor_generator schema dump ./lib/database/databases.dart schema.json

@UseMoor(tables: [Subjects, Attendances])
class Database extends _$Database {
  Database()
      : super(
          FlutterQueryExecutor.inDatabaseFolder(
              path: 'db.sqlite', logStatements: true),
        );

  @override
  int get schemaVersion => 4;

  ///Migration
  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 3) {
          // we added the dueDate property in the change from version 1
          await m.addColumn(subjects, subjects.updatedAt);
          await m.alterTable(
            TableMigration(
                subjects,
                columnTransformer: {
                  subjects.createdAt: subjects.createdAt.cast<int>(),
                }
            ),
          );
        }
      });

  /// Subjects
  //Future<List<Subject>> getAllSubjects() => select(subjects).get();

  Future<List<Subject>> getAllSubjects() {
    return (select(subjects)..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])).get();
  }

  Stream<List<Subject>> get watchAllModes => select(subjects).watch();

  Future insertSubject(Subject subject) => into(subjects).insert(subject);

  Future deleteSubject(Subject subject) => delete(subjects).delete(subject);

  Future deleteAllSubjects() => delete(subjects).go();

  Future updateSubject(Subject subject) {
    return (update(subjects)..where((t) => t.id.equals(subject.id))).write(
      SubjectsCompanion(name: Value(subject.name), updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Future updateTime(Subject subject) {
    return (update(subjects)..where((t) => t.id.equals(subject.id))).write(
      SubjectsCompanion(updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }


  /// Attendance
  Future<List<Attendance>> getAllAttendance() => select(attendances).get();

  Future insertAttendance(Attendance attendance) =>
      into(attendances).insert(attendance);

  Future deleteAllAttendance() => delete(attendances).go();

  Future deleteAllAttendanceOFSubject(Attendance attendance) {
    return (delete(attendances)
          ..where((t) => t.subjectId.equals(attendance.subjectId)))
        .go();
  }

  Future updateAttendance(Attendance attendance) {
    return (update(attendances)..where((t) => t.id.equals(attendance.id)))
        .write(
      AttendancesCompanion(attendanceValue: Value(attendance.attendanceValue)),
    );
  }

  Future getAttendanceByDate(DateTime date, int subjectId) {
    return (select(attendances)
          ..where((tbl) => tbl.date.equals(date))
          ..where((tbl) => tbl.subjectId.equals(subjectId)))
        .getSingle();
  }

  Future<List<Attendance>> getAttendanceBetween(
      DateTime startDate, DateTime endDate, int subjectId) {
    final dayStart = DateTime(startDate.year, startDate.month, startDate.day);
    final dayEnd = DateTime(endDate.year, endDate.month, endDate.day);

    return (select(attendances)
          ..where((tbl) => tbl.date.isBetweenValues(dayStart, dayEnd))
          ..where((tbl) => tbl.subjectId.equals(subjectId))
          ..orderBy([(record) => OrderingTerm(expression: record.date)]))
        .get();
  }
}
