import 'package:attendance_calendar/controller/main_controller.dart';
import 'package:attendance_calendar/database/database.dart';
import 'package:attendance_calendar/view/widgets/alert_dialog.dart';
import 'package:attendance_calendar/view/widgets/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:in_app_review/in_app_review.dart';
import '../constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends MainController {
  TextEditingController name = TextEditingController();

  final _subjectList = List<Subject>().obs;

  set subjectList(List<Subject> value) {
    if (value.length > 0) {
      value.forEach((element) {
        _subjectList.add(Subject(
            id: element.id,
            name: element.name,
            createdAt: element.createdAt,
            updatedAt: element.updatedAt));
      });
    }
  }

  get subjectList => this._subjectList;

  @override
  void onInit() async {
    super.onInit();
    RateMyApp _rateMyApp = RateMyApp(
        preferencesPrefix: 'rateMyApp_',
        minDays: 3,
        minLaunches: 7,
        remindDays: 2,
        remindLaunches: 5);

    _rateMyApp.init().then((_) {
      if (_rateMyApp.shouldOpenDialog) {
        //conditions check if user already rated the app
        _rateMyApp.showRateDialog(
          Get.context,
          title: 'What do you think about Our App?',
          message: 'Please leave a rating',
          rateButton: 'RATE',
          listener: (button) {
            // The button click listener (useful if you want to cancel the click event).
            switch (button) {
              case RateMyAppDialogButton.rate:
                final InAppReview inAppReview = InAppReview.instance;
                if (inAppReview.isAvailable() != null) {
                  inAppReview.requestReview();
                }
                break;
              case RateMyAppDialogButton.later:
                break;
              case RateMyAppDialogButton.no:
                var sh = SharedPreferences.getInstance();
                DoNotOpenAgainCondition().isMet;
                break;
            }

            return true; // Return false if you want to cancel the click event.
          },
          dialogStyle: DialogStyle(
            titleAlign: TextAlign.center,
            messageAlign: TextAlign.center,
            messagePadding: EdgeInsets.only(bottom: 20.0),
          ),
          ignoreNativeDialog: false,
          onDismissed: () =>
              _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed),
        );
      }
    });
  }

  @override
  void onClose() {
    name.dispose();
  }

  @override
  void onReady() {
    readAll();
    super.onReady();
  }

  void readAll() async {
    try {
      List<Subject> s = await db.getAllSubjects();
      await subjectList(s);
    } catch (e) {
      errorSnackbar(msg: e.toString());
    }
  }

  bool doNameValidation() {
    if (name.text.isNotEmpty && name.text.length > 2) {
      return true;
    }
    if (name.text.isEmpty) {
      errorSnackbar(msg: 'home.controller.enter.subject'.tr);
    } else if (name.text.length < 3) {
      errorSnackbar(msg: "home.controller.minimum.character.required".tr);
    } else {
      errorSnackbar(msg: 'home.controller.enter.subject'.tr);
    }
    return false;
  }

  void save() {
    try {
      db.insertSubject(Subject(
          name: this.name.text,
          updatedAt: DateTime.now().millisecondsSinceEpoch));
      readAll();
      name.clear();
      Get.back();
      successSnackbar(msg: 'home.controller.subject.added.successfully'.tr);
      if (GetStorage().read(IS_FIRST_TIME)) {
        showOnFirstAdd();
      }
    } catch (e) {
      errorSnackbar(msg: e.toString());
    }
  }

  Future<void> showOnFirstAdd() async {
    var result = await alertDialog(
        title: 'home.controller.firstTime.title'.tr,
        subtitle: "home.controller.firstTime.Subtitle".tr,
        color: Colors.green);
    if (result != null && result) GetStorage().write(IS_FIRST_TIME, false);
  }

  void delete(int subID) {
    try {
      db.deleteSubject(Subject(id: subID));
      db.deleteAllAttendanceOFSubject(Attendance(subjectId: subID));
      readAll();
      successSnackbar(msg: 'home.controller.subject.deleted.successfully'.tr);
    } catch (e) {
      errorSnackbar(msg: e.toString());
    }
  }

  void reset(int subID) {
    try {
      db.deleteAllAttendanceOFSubject(Attendance(subjectId: subID));
      successSnackbar(msg: 'home.controller.reset.successful'.tr);
    } catch (e) {
      errorSnackbar(msg: e.toString());
    }
  }

  void updateName(int subID) {
    try {
      db.updateSubject(Subject(id: subID, name: this.name.text));
      readAll();
      name.clear();
      Get.back();
      successSnackbar(msg: 'home.controller.Subject.Updated.Successfully'.tr);
    } catch (e) {
      errorSnackbar(msg: e.toString());
    }
  }
}
