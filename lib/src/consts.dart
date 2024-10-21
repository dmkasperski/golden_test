import 'package:flutter/material.dart';
import 'package:golden_test/src/device.dart';

bool disableInfiniteAnimationsInTests = false;

List<Locale> goldenTestLocales = [const Locale('en', 'US')];

List<Device> supportedDevices = [
  Device.noInsets(),
  Device.iphone15Pro(),
  Device.pixel9ProXL(),
  Device.ipadPro12(),
  Device.macbookPro14(),
  Device.browser(),
];

List<Brightness> goldenTestSupportedModes = [Brightness.light, Brightness.dark];

ThemeData themeInTests = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  fontFamily: 'Roboto',
  fontFamilyFallback: const ['Roboto'],
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.light,
  ),
);

ThemeData darkThemeInTests = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  fontFamily: 'Roboto',
  fontFamilyFallback: const ['Roboto'],
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.dark,
  ),
);
