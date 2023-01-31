import 'dart:io';

import 'package:attendance_calendar/constants.dart';
import 'package:attendance_calendar/controller/main_controller.dart';
import 'package:attendance_calendar/controller/settings_controller.dart';
import 'package:attendance_calendar/routes/app_pages.dart';
import 'package:attendance_calendar/services/local_auth.dart';
import 'package:attendance_calendar/services/localization_service.dart';
import 'package:attendance_calendar/theme/app_theme.dart';
import 'package:attendance_calendar/translations/app_translations.dart';
import 'package:attendance_calendar/view/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager.initialize(callbackDispatcher);
  // local storage
  await GetStorage.init();

  final LocalAuthentication auth = LocalAuthentication();

  if (GetStorage().read(LOCAL_AUTH) == true) {
    LocalAuthService().authenticate(auth);
  }

  // main ui and app
  initializeDateFormatting().then((_) => runApp(MainApp()));
}

// ignore: missing_return
Future onSelectNotification(String payload) {
  print('Payload: $payload');
}

Future<void> getMessage(flip) async {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
 print(await _firebaseMessaging.getToken());
  _firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) async {
    print('on message $message');
    showFCMNotification(message,flip);
    //setState(() => _message = message["notification"]["title"]);
  }, onResume: (Map<String, dynamic> message) async {
    print('on resume $message');
    showFCMNotification(message,flip);
  }, onLaunch: (Map<String, dynamic> message) async {
    print('on launch $message');
    showFCMNotification(message,flip);
  });
}

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) {
    print("Native called daily backup task at ${DateTime.now().toString()}");
    SettingsController settingsController = SettingsController();
    print(
        "${settingsController.read("accountDetails")} && ${settingsController.read(DAILY_BACKUP)}");
    if (settingsController.read("accountDetails") != null &&
        settingsController.read(DAILY_BACKUP) == true) {
      print("Backing Up");
      settingsController.driveBackup();
    }
    return Future.value(true);
  });
}

showNotificationWithDefaultSound(flip) async {
  var time = new Time(20, 40, 0);
  var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
    'ChannelID',
    'Reminders',
    'Give daily reminders',
    importance: Importance.max,

    // priority: Priority.high
  );
  var iOSPlatformChannelSpecifics = new IOSNotificationDetails();

  // initialise channel platform for both Android and iOS device.
  var platformChannelSpecifics = new NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  // await flip.show(0, 'Attendance',
  //      'Mark Your Daily Attendance for today', platformChannelSpecifics);
  print("Notification Scheduled at $time");
  await flip.showDailyAtTime(0, 'Attendance',
      'Mark Your Daily Attendance for today', time, platformChannelSpecifics);
}

showFCMNotification(message,flip) async {
  var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
    'ChannelID2',
    'Notification',
    'Push Notifications',
    importance: Importance.max,

    // priority: Priority.high
  );
  var iOSPlatformChannelSpecifics = new IOSNotificationDetails();

  // initialise channel platform for both Android and iOS device.
  var platformChannelSpecifics = new NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  // await flip.show(0, 'Attendance',
  //      'Mark Your Daily Attendance for today', platformChannelSpecifics);
  var msg =  message["notification"];
  await flip.show(0, msg["title"].toString(),
      msg["body"].toString(), platformChannelSpecifics);


}

createDir() async {
  if (await Permission.storage.request().isGranted) {
    Directory baseDir =
        await getApplicationDocumentsDirectory(); //works for both iOS and Android
    String dirToBeCreated = 'title'.tr;
    String finalDir = "$baseDir/$dirToBeCreated";
    var dir = Directory(finalDir);
    bool dirExists = await dir.exists();
    if (!dirExists) {
      Directory(finalDir)
          .createSync(); //pass recursive as true if directory is recursive
    }
  }
}

Future<void> checkForUpdate() async {
  InAppUpdate.checkForUpdate().then((info) {
    info?.updateAvailable == true
        ? InAppUpdate.startFlexibleUpdate().then((_) {
            InAppUpdate.completeFlexibleUpdate().then((_) {
            }).catchError((e) => print(e));
          }).catchError((e) => print(e))
        // ignore: unnecessary_statements
        : null;
  }).catchError((e) => print(e));
}

Future<void> initServices() async {
  // Controller
  MainController mainController = Get.put(MainController());
  SettingsController settingsController = Get.put(SettingsController());

  GetStorage().writeIfNull(IS_FIRST_TIME, true);

  var brightness = SchedulerBinding.instance.window.platformBrightness;
  bool darkModeOn = brightness == Brightness.dark;

  print(darkModeOn);

  (darkModeOn)
      ? GetStorage().writeIfNull(DARK_MODE, true)
      : GetStorage().writeIfNull(DARK_MODE, false);

  // check dark mode
  bool dm = settingsController.read(DARK_MODE);

  if (dm == true) {
    Get.changeTheme(darkThemeData);
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();
  var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
  var IOS = new IOSInitializationSettings();

  // initialise settings for both Android and iOS device.
  var initSettings = new InitializationSettings(android: android, iOS: IOS);
  flutterLocalNotificationsPlugin.initialize(initSettings,
      onSelectNotification: onSelectNotification);

  showNotificationWithDefaultSound(flutterLocalNotificationsPlugin);

  getMessage(flutterLocalNotificationsPlugin);

  checkForUpdate();
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowMaterialGrid: false,
      debugShowCheckedModeBanner: false,
      title: 'Attendance',
      themeMode: ThemeMode.system,
      //theme: ThemeData.light(),
      //darkTheme: ThemeData.dark(),
      theme: liteThemeData,
      // darkTheme: darkThemeData,
      initialRoute: Routes.INITIAL,
      defaultTransition: Transition.cupertino,
      home: Home(),
      locale: LocalizationService().currentLocals(),
      fallbackLocale: LocalizationService.fallbackLocale,
      translations: LocalizationService(),
      builder: EasyLoading.init(),
      translationsKeys: AppTranslation.translations,
      getPages: AppPages.pages,
      onReady: () async {
        await initServices();
      },
    );
  }
}
