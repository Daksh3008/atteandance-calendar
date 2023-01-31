import 'package:attendance_calendar/view/widgets/alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:attendance_calendar/controller/main_controller.dart';
import 'package:attendance_calendar/services/GoogleAuthClient.dart';
import 'package:attendance_calendar/view/widgets/snackbar.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:get_storage/get_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';
import '../constants.dart';
import 'home_controller.dart';

class SettingsController extends MainController {
  HomeController controller = Get.put(HomeController());
  final box = GetStorage();

  GoogleSignIn _googleSignIn =
      GoogleSignIn.standard(scopes: [drive.DriveApi.DriveAppdataScope]);
  GoogleSignInAccount accountDetails;

  @override
  void onReady() {
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount account) async {
      if (account != null) {
        accountDetails = account;
        await write('accountDetails', accountDetails.toString());
        final driveApi = await initializeAuthHeaders();
        drive.FileList fileList = await backupSearch(driveApi);

        if (fileList.files != null) {
          List val = fileList.toJson()['files'];
          if (val.length > 0) {
            String createdTime = val[0]['createdTime'];
            String updatedTime = await dateFormatting(createdTime);
            await write('updatedTime', updatedTime);
          }
        }
      }
    });
    _googleSignIn.signInSilently();
    super.onReady();
  }

  @override
  void onInit() {
    super.onInit();
  }

  write(key, value) {
    box.write(key, value);
    update();
  }

  remove(key) {
    box.remove(key);
    update();
  }

  read(key) {
    var va = box.read(key);
    if (va == null) {
      return false;
    }

    if (va == 'false') {
      return false;
    }

    if (va == 'true') {
      return true;
    }
    return va;
  }

  void clearAllData() async {
    try {
      var result = await alertDialog(
          title: 'settings.clear.all.data'.tr,
          subtitle: 'settings.clear.subtitle'.tr,
          color: Colors.green);
      if (result != null && result) {
        EasyLoading.show(
            maskType: EasyLoadingMaskType.black, dismissOnTap: false);
        await db.deleteAllSubjects();
        await db.deleteAllAttendance();
        controller.subjectList().clear();
        controller.readAll();
        EasyLoading.dismiss();
        successSnackbar(msg: 'settings.Cleared.Data.Successfully'.tr);
      }
    } catch (e) {
      EasyLoading.dismiss();
      errorSnackbar(msg: e.toString());
    }
  }

  ///
  /// GOOGLE BACKUP AND RESTORE SECTION
  initializeAuthHeaders() async {
    try {
      var account = accountDetails;
      final authHeaders = await account.authHeaders;
      if (authHeaders != null) {
        final authenticateClient = GoogleAuthClient(authHeaders);
        return drive.DriveApi(authenticateClient);
      }
    } catch (e) {
      errorSnackbar(msg: 'settings.authentication.not.successful'.tr);
    }
  }

  backupSearch(drive.DriveApi driveApi) async {
    drive.FileList fileList = await driveApi.files.list(
        spaces: "appDataFolder",
        $fields: 'files(id,name,size,starred,createdTime)',
        orderBy: "createdTime");

    return fileList;
  }

  dateFormatting(String s) async {
    String restrictFractionalSeconds(String dateTime) =>
        dateTime.replaceFirstMapped(RegExp("(\\.\\d{3})\\d+"), (m) => m[1]);

    var dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss.mmmZ")
        .parse(restrictFractionalSeconds(s));
    String formattedDate = dateFormat2.format(dateTime.toLocal());

    return formattedDate;
  }



  Future<void> googleSignIn() async {
    ///signIn
    try {
      EasyLoading.show(
          maskType: EasyLoadingMaskType.black, dismissOnTap: false);
      final GoogleSignInAccount account = await _googleSignIn.signIn();
      await write('accountDetails', account.toString());

      final driveApi = await initializeAuthHeaders();
      if (driveApi == null) {
        EasyLoading.dismiss();
        return null;
      }

      drive.FileList fileList = await backupSearch(driveApi);

      if (fileList.files != null) {
        List val = fileList.toJson()['files'];
        if (val.length > 0) {
          String createdTime = val[0]['createdTime'];
          String updatedTime = await dateFormatting(createdTime.toString());
          await write('updatedTime', updatedTime);
          EasyLoading.dismiss();
          var result = await alertDialog(
              title: 'settings.onSignInRestore.title'.tr,
              subtitle: "settings.backup.subtitle".tr,
              color: Colors.green);
          if (result != null && result) driveRestore();
        }
        EasyLoading.dismiss();
      }
      successSnackbar(msg: "Successfully signed in ${account.displayName}!!!");
    } on PlatformException catch (e) {
      EasyLoading.dismiss();
      errorSnackbar(msg: e.toString());
    }
  }

  Future<void> googleSignOut() async {
    try {
      EasyLoading.show(
          maskType: EasyLoadingMaskType.black, dismissOnTap: false);
      await _googleSignIn.disconnect();
      accountDetails = null;
      await remove('updatedTime');
      await remove('accountDetails');
      Workmanager.cancelAll();
      update();
      EasyLoading.dismiss();
      successSnackbar(msg: 'settings.signed.out.successfully'.tr);
    } on PlatformException catch (e) {
      EasyLoading.dismiss();
      errorSnackbar(msg: e.details.toString());
    }
  }

  Future<void> driveBackup() async {
    ///Headers
    try {
      EasyLoading.show(
          maskType: EasyLoadingMaskType.black,
          dismissOnTap: false,
          status: "Backing Up Data to Google Drive");
      final driveApi = await initializeAuthHeaders();
      if (driveApi == null) {
        EasyLoading.dismiss();
        return null;
      }

      drive.FileList fileList = await backupSearch(driveApi);

      String fileID;

      ///Check if backup already exists
      if (fileList.files != null) {
        List val = fileList.toJson()['files'];
        if (val.length > 0) {
          fileID = val[0]['id'];
        }
      }

      ///Upload
      drive.File driveFile = new drive.File();
      var file = await _localFile;
      driveFile.parents = ["appDataFolder"];
      driveFile.name = 'db.sqlite';
      final result = await driveApi.files.create(driveFile,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()));
      EasyLoading.dismiss();
      if (result != null) {
        successSnackbar(msg: "settings.controller.Backed.Up.successfully".tr);
        if (fileID != null)
          await driveApi.files.delete(fileID, enforceSingleParent: true);
        await write('updatedTime', dateFormat2.format(DateTime.now()));
      }
    } catch (e) {
      EasyLoading.dismiss();
      errorSnackbar(msg: e.toString());
    }
  }

  Future<void> driveRestore() async {
    ///Headers
    EasyLoading.show(maskType: EasyLoadingMaskType.black, dismissOnTap: false);
    try {
      EasyLoading.show(
          maskType: EasyLoadingMaskType.black, dismissOnTap: false);
      List<int> dataStore = [];
      final driveApi = await initializeAuthHeaders();
      if (driveApi == null) {
        EasyLoading.dismiss();
        return null;
      }

      drive.FileList fileList = await backupSearch(driveApi);

      if (fileList.files != null) {
        List val = fileList.toJson()['files'];
        if (val.length > 0) {
          String fileID = val[0]['id'];
          drive.Media response = await driveApi.files
              .get(fileID, downloadOptions: drive.DownloadOptions.FullMedia);

          ///Build Data

          response.stream.listen((data) {
            dataStore.insertAll(dataStore.length, data);
          }, onDone: () async {
            ///WRITE TO NEW FILE
            File file = File(
                '/data/data/in.sourceorigin.attendancecalendar/databases/db_restored.sqlite'); //Create a dummy file
            await file.writeAsBytes(dataStore);
            String dir = path.dirname(file.path);

            ///BACKUP OLD FILE
            File oldFile = File(
                '/data/data/in.sourceorigin.attendancecalendar/databases/db.sqlite');
            String oldPath = path.join(dir, 'db_old.sqlite');
            oldFile.copySync(oldPath);

            ///COPY NEW FILE INTO OLD FILE
            String newPath = path.join(dir, 'db.sqlite');
            file.copySync(newPath);

            ///Data Build Complete

            controller.readAll();
            successSnackbar(msg: "settings.restored.successfully".tr);
          }, onError: (error) {
            errorSnackbar(msg: error.toString());
          });
        }
        EasyLoading.dismiss();
        await write(IS_FIRST_TIME, false);
      }
    } catch (e) {
      EasyLoading.dismiss();
      errorSnackbar(msg: e.toString());
    }
  }

  Future<File> get _localFile async {
    final path = '/data/data/in.sourceorigin.attendancecalendar';
    return File('$path/databases/db.sqlite');
  }
}
