import 'package:flutter/material.dart';
import 'package:golden_test/src/device.dart';

bool disableInfiniteAnimationsInGoldenTests = false;

List<Locale> goldenTestSupportedLocales = [const Locale('en', 'US')];
List<LocalizationsDelegate<dynamic>> goldenTestLocalizationsDelegates = [];

List<Device> goldenTestSupportedDevices = [
  Device.noInsets(),
  Device.iphone15Pro(),
  Device.pixel9ProXL(),
  Device.ipadPro12(),
  Device.browser(),
];

List<Brightness> goldenTestSupportedModes = [Brightness.light, Brightness.dark];

ThemeData goldenTestThemeInTests = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.light,
  ),
);

ThemeData goldenTestDarkThemeInTests = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.dark,
  ),
);
