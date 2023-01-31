import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../constants.dart';

class LocalAuthService extends GetxService {
  Future<void> authenticate(LocalAuthentication auth) async {
    bool authenticated = false;
    bool canCheckBiometrics = await auth.canCheckBiometrics;

    List availableBiometrics = await auth.getAvailableBiometrics();
    print("checkBiometric");
    print((canCheckBiometrics));
    print("List");
    print(availableBiometrics);

    /// The device does not support biometric scan

    try {
      if (canCheckBiometrics) {
        authenticated = await auth.authenticateWithBiometrics(
            localizedReason: 'Authentication required to access the app.',
            useErrorDialogs: true,
            stickyAuth: true);
      }
    } catch (e) {
      if (e.code == auth_error.notAvailable) {
        print(e);
      } else
        print(e);
      GetStorage().write(LOCAL_AUTH, false);
    }

    if (!authenticated) {
      // auth.stopAuthentication();
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }
}
