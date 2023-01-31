import 'package:attendance_calendar/ads/show_ads.dart';
import 'package:attendance_calendar/constants.dart';
import 'package:attendance_calendar/controller/home_controller.dart';
import 'package:attendance_calendar/controller/main_controller.dart';
import 'package:attendance_calendar/database/database.dart';
import 'package:attendance_calendar/view/widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceController extends MainController {
  CalendarController calendarController = CalendarController();

  /// Current Attendance Database Value
  final _attendance = List<Attendance>().obs;

  // For reports
  final present = List<Attendance>().obs;
  final absent = List<Attendance>().obs;
  final halfDay = List<Attendance>().obs;

  set setAttendance(List<Attendance> value) {
    if (value.length > 0) {
      value.forEach((element) {
        _attendance.add(Attendance(
            id: element.id,
            subjectId: element.subjectId,
            date: element.date,
            note: element.note,
            attendanceValue: element.attendanceValue,
            createdAt: element.createdAt));
      });
    }
  }

  get attendance => this._attendance;

  /// Select Attendance Radio Button
  final _selectedAttendanceValue = RxInt(ATTENDANCE_TYPE['present']);

  set setSelectedAttendance(int val) {
    _selectedAttendanceValue.value = val;
  }

  get getSelectedAttendance => this._selectedAttendanceValue.value;

  ///
  /// Calendar Events
  final _events = Map<DateTime, List>().obs;

  set events(arr) {
    _events.clear(); // clear previous first
    arr.map((Attendance i) {
      if (_events[i.date] == null) {
        _events[i.date] = [];
      }
      _events[i.date].add(i.attendanceValue);
    }).toList();
  }

  get events => _events();

  @override
  void onInit() {
    calendarController = CalendarController();
    ShowAds().showBannerAd();
    super.onInit();
  }

  @override
  void onClose() {
    calendarController.dispose();
    _attendance.clear();
    _events.clear();
    ShowAds().disposeAds();
    super.onClose();
  }

  @override
  void dispose() {
    ShowAds().disposeAds();
    calendarController.dispose();
    super.dispose();
  }

  /// Crud operations
  void saveAttendance({int subjectId, DateTime date, int attendanceValue, String note}) async {
    try {
      Attendance oldData = await db.getAttendanceByDate(date, subjectId);
      if (oldData != null) {
        await db.updateAttendance(Attendance(id: oldData.id, attendanceValue: getSelectedAttendance));
        await db.updateTime(Subject(id: subjectId, updatedAt: DateTime.now().millisecondsSinceEpoch));
        Get.back();
        successSnackbar(msg: 'attendance.controller.Attendance.Updated.Successfully'.tr);
      } else {
        await db.insertAttendance(Attendance(subjectId: subjectId, attendanceValue: getSelectedAttendance, date: date, note: note));
        await db.updateTime(Subject(id: subjectId, updatedAt: DateTime.now().millisecondsSinceEpoch));
        Get.back();
        successSnackbar(msg: 'attendance.controller.Attendance.Added.Successfully'.tr);
      }
    } catch (e) {
      print("*********** ERROR : $e");
      errorSnackbar(msg: 'attendance.controller.error.saving.or.reading.data'.tr);
    }

    HomeController().readAll();

    getEventsBetweenDates(calendarController.visibleDays.first, calendarController.visibleDays.last, subjectId);
  }

  Future<void> getEventsBetweenDates(DateTime start, DateTime end, subjectId) async {
    try {
      List<Attendance> rec = await db.getAttendanceBetween(start, end, subjectId);
      events.clear();
      attendance.clear();
      events = rec;
      setAttendance = rec;
      pieChartData(rec);
      update();
    } catch (e) {
      errorSnackbar(msg: e.toString());
    }
  }

  void pieChartData(arr) {
    // clear old data first
    present.clear();
    absent.clear();
    halfDay.clear();

    // add new values
    arr.map((Attendance i) {
      if (i.attendanceValue == 1) present.add(i);
      if (i.attendanceValue == 2) absent.add(i);
      if (i.attendanceValue == 3) halfDay.add(i);
    }).toList();
  }

  /// Current Attendance Report

}
