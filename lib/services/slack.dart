import 'dart:convert';
import 'package:attendance_calendar/view/widgets/snackbar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';
import '../constants.dart';
import 'dart:io';
import 'package:get/get.dart';

sendSlackMessage(Map feedback) async {
  try {
    if (feedback['rating'] == 0) {
      throw Exception("No rating found");
    }
    if (feedback['feedback'].isEmpty || feedback['feedback'] == ' ') {
      throw Exception("No feedback found");
    }
    print("=======${feedback['feedback']}===========");
    EasyLoading.show(maskType: EasyLoadingMaskType.black, dismissOnTap: false);
    //Slack's Webhook URL
    var url = slackURL;

    Map<String, dynamic> deviceData;
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
      return <String, dynamic>{
        'version.securityPatch': build.version.securityPatch,
        'version.sdkInt': build.version.sdkInt,
        'version.release': build.version.release,
        'version.previewSdkInt': build.version.previewSdkInt,
        'version.incremental': build.version.incremental,
        'version.codename': build.version.codename,
        'version.baseOS': build.version.baseOS,
        'board': build.board,
        'bootloader': build.bootloader,
        'brand': build.brand,
        'device': build.device,
        'display': build.display,
        'fingerprint': build.fingerprint,
        'hardware': build.hardware,
        'host': build.host,
        'id': build.id,
        'manufacturer': build.manufacturer,
        'model': build.model,
        'product': build.product,
        'supported32BitAbis': build.supported32BitAbis,
        'supported64BitAbis': build.supported64BitAbis,
        'supportedAbis': build.supportedAbis,
        'tags': build.tags,
        'type': build.type,
        'isPhysicalDevice': build.isPhysicalDevice,
        'androidId': build.androidId,
        'systemFeatures': build.systemFeatures,
      };
    }

    Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
      return <String, dynamic>{
        'name': data.name,
        'systemName': data.systemName,
        'systemVersion': data.systemVersion,
        'model': data.model,
        'localizedModel': data.localizedModel,
        'identifierForVendor': data.identifierForVendor,
        'isPhysicalDevice': data.isPhysicalDevice,
        'utsname.sysname:': data.utsname.sysname,
        'utsname.nodename:': data.utsname.nodename,
        'utsname.release:': data.utsname.release,
        'utsname.version:': data.utsname.version,
        'utsname.machine:': data.utsname.machine,
      };
    }

    try {
      if (Platform.isAndroid) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      }
    } on PlatformException {
      errorSnackbar(msg: 'slack.failed.to.get.platform.version'.tr);
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    //Makes request headers
    Map<String, String> requestHeader = {
      'Content-type': 'application/json',
    };

    var request = {
      "text":
          "Rating : ${feedback['rating']} \n\ Feedback : ${feedback['feedback'] != null ? feedback['feedback'] : "Null Feedback"}",
      "attachments": [
        {"title": "slack.title".tr, "text": deviceData.toString()}
      ],
    };

    print("+++++++++++++++++++++++++++++ ${json.encode(request)}");

    var result = await http
        .post(url, body: json.encode(request), headers: requestHeader)
        .then((response) {
      print(response.body);
    });
    successSnackbar(msg: "slack.feedback.sent.successfully".tr);
    EasyLoading.dismiss();
    Get.back();
  } catch (e) {
    EasyLoading.dismiss();
    Get.back();
    errorSnackbar(msg: e.toString());
  }
}
