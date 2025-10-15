import 'package:flutter/material.dart';

class Device {
  final String? name;
  final double devicePixelRatio;
  final double width;
  final double height;
  final EdgeInsets insets;

  const Device({
    this.name = 'default',
    this.devicePixelRatio = 1,
    this.width = 420,
    this.height = 800,
    this.insets = EdgeInsets.zero,
  });

  const Device.noInsets()
      : this(
          name: 'no insets',
          devicePixelRatio: 3,
          width: 393,
          height: 852,
          insets: const EdgeInsets.all(0),
        );

  const Device.iphone15Pro()
      : this(
          name: 'iphone 15 pro',
          devicePixelRatio: 3,
          width: 393,
          height: 852,
          insets: const EdgeInsets.only(top: 44, bottom: 34),
        );

  const Device.pixel9ProXL()
      : this(
          name: 'pixel 9 pro xl',
          devicePixelRatio: 3,
          width: 430,
          height: 926,
          insets: const EdgeInsets.only(top: 48, bottom: 40),
        );

  const Device.ipadPro12()
      : this(
          name: 'ipad pro 12',
          devicePixelRatio: 2,
          width: 1024,
          height: 1366,
          insets: const EdgeInsets.only(top: 48, bottom: 40),
        );

  const Device.browser()
      : this(
          name: 'browser',
          devicePixelRatio: 4,
          width: 3024,
          height: 1964,
          insets: const EdgeInsets.only(top: 120),
        );

  Device copyWith(
          {final double? devicePixelRatio,
          final double? width,
          final double? height,
          final EdgeInsets? insets,
          final String? name}) =>
      Device(
        name: name,
        devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
        width: width ?? this.width,
        height: height ?? this.height,
        insets: insets ?? this.insets,
      );
}
