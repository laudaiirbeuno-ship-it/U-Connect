import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Demo_Localization.dart';

const String LAGUAGE_CODE = 'languageCode';

setPrefrenceBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String languageCode = prefs.getString(LAGUAGE_CODE) ?? "pt";
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case "en":
      return const Locale("en", 'GB'); // Inglês Britânico
    case "pt":
      return const Locale("pt", "pt_BR");
    case "es":
      return const Locale("es", "ES"); // Espanhol
    case "fr":
      return const Locale("fr", "FR"); // Francês
    case "it":
      return const Locale("it", "IT"); // Italiano
    default:
      return const Locale("pt", "pt_BR");
  }
}

String? getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context)!.translate(key);
}
