import 'package:attendance_calendar/constants.dart';
import 'package:attendance_calendar/database/database.dart';
import 'package:attendance_calendar/routes/app_pages.dart';
import 'package:attendance_calendar/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class MainController extends GetxController {
  final Database db = Database();

  ///
  /// Authentication
  ///
  getLocalAuthSetting() {
    /// If setting does not allow then do not process further
    /// do nothing
    final localAuth = GetStorage().read(LOCAL_AUTH);
    if (localAuth == null) {
      return false;
    }
    if (localAuth == 'true') return true;
    if (localAuth == 'false') return false;
    return localAuth;
  }

  ///
  /// Navigation
  ///
  goToSettingsPage() {
    Get.toNamed(Routes.SETTINGS);
  }

  goToSubjectsPage({int id, String name}) {
    Get.toNamed(Routes.SUBJECTS, arguments: [id, name]);
  }

  ///
  /// Theme Settings
  ///
  changeTheme() {
    Get.changeTheme(Get.isDarkMode ? liteThemeData : darkThemeData);
  }
}
