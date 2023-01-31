import 'package:attendance_calendar/controller/attendance_controller.dart';
import 'package:attendance_calendar/controller/home_controller.dart';
import 'package:attendance_calendar/controller/settings_controller.dart';
import 'package:get/get.dart';

class SettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(()=>HomeController());
  }
}

class AttendanceBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AttendanceController>(()=>AttendanceController());
  }
}
