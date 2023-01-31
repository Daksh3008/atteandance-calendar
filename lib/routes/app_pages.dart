import 'package:attendance_calendar/controller/bindings/bindings.dart';
import 'package:attendance_calendar/view/home.dart';
import 'package:attendance_calendar/view/settings.dart';
import 'package:attendance_calendar/view/subject.dart';
import 'package:get/get.dart';

part './app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.INITIAL, page: () => Home()),
    GetPage(name: Routes.SETTINGS, page: () => Settings(), bindings: [SettingsBinding()]),
    GetPage(name: Routes.SUBJECTS, page: () => SubjectPage()),
  ];
}
