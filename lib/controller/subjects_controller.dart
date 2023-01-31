import 'package:attendance_calendar/controller/main_controller.dart';
import 'package:attendance_calendar/database/database.dart';
import 'package:get/get.dart';

class SubjectsController extends MainController {
  SubjectsController();

  final _obj = List<Subject>().obs;

  set obj(value) {
    value.forEach((element) {
      // _obj.add(Subject());
    });
  }

  get obj => this._obj;

  @override
  void onInit() async {
    // obj(Database().getAllSubjects());
    super.onInit();
  }
  //
  // void updateSubject(String key, String value) async {
  //   try {
  //     await Database().updateSubject(Subject());
  //     _obj.add(Subject());
  //   } catch (err) {
  //     Get.snackbar("Error", err.toString());
  //   }
  // }
}
