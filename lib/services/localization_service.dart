import 'package:attendance_calendar/translations/en_us_translations.dart';
import 'package:attendance_calendar/translations/hi_in_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationService extends Translations {
  final storage = GetStorage();

  static final _langFormatted = {"hi": "हिन्दी", "en": "English"};

  // fallbackLocale saves the day when the locale gets in trouble
  static final fallbackLocale = Locale('en', 'US');

  // Supported languages
  // Needs to be same order with locales
  static final langs = [
    'English',
    'Hindi',
  ];

  // Supported locales
  // Needs to be same order with langs
  static final locales = [
    Locale('en', 'US'),
    Locale('hi', 'IN'),
  ];

  // Keys and their translations
  // Translations are separated maps in `lang` file
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUs,
        'hi_IN': hiIn,
      };

  // Gets locale from language, and updates the locale
  void changeLocale(String lang) {
    storage.write("selectedLang", lang);
    final locale = _getLocaleFromLanguage(lang);
    Get.updateLocale(locale);
    Get.back();
  }

  Locale currentLocals() {
    final lang = storage.read('selectedLang');

    if (lang != null) {
      return _getLocaleFromLanguage(lang);
    }
    return Locale('en', 'US');
  }

  String currentLangCode() {
    return this.currentLocals().languageCode;
  }

  String currentLangFormatted() {
    return _langFormatted[this.currentLocals().languageCode];
  }

  // Finds language in `langs` list and returns it as Locale
  Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale;
  }
}
