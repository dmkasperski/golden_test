import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:golden_test/golden_test.dart';

// Used as the FadeInImage placeholder while the network image loads.
final _redPlaceholder = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAApElEQVR42u3RAQ0AAAjD'
  'MO5fNCCDkC5z0HTVrisFCBABASIgQAQEiIAAAQJEQIAICBABASIgQAREQIAICBABASIg'
  'QAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQARE'
  'QIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAQECBAgAgJEQIAIyPcGFY7H'
  'nV2aPXoAAAAASUVORK5CYII=',
);

void main() {
  // Covers every widget type that loads network images:
  //   • Image.network / NetworkImage  — intercepted via HttpOverrides.global
  //   • FadeInImage with NetworkImage — same interception
  //   • DecoratedBox with NetworkImage — same interception
  //   • CachedNetworkImage            — served by GoldenTestCacheManager
  //     (registered globally in flutter_test_config.dart via goldenTestCachedNetworkImageManager)
  goldenTest(
    name: 'Network image stub - all widget types',
    supportedDevices: [const Device.noInsets()],
    supportedLocales: [const Locale('en')],
    builder: (_) => Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network('https://example.com/image.png', width: 100, height: 100),
            const SizedBox(height: 12),
            FadeInImage(
              placeholder: MemoryImage(_redPlaceholder),
              image: const NetworkImage('https://example.com/avatar.jpg'),
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 12),
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://example.com/banner.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: SizedBox(width: 200, height: 60),
            ),
            const SizedBox(height: 12),
            CachedNetworkImage(
              imageUrl: 'https://example.com/cached.png',
              width: 100,
              height: 100,
            ),
          ],
        ),
      ),
    ),
  );

  // Verifies the stub doesn't interfere with asset images rendered in the same frame.
  goldenTest(
    name: 'Network image stub - mixed asset and network',
    supportedDevices: [const Device.noInsets()],
    supportedLocales: [const Locale('en')],
    builder: (_) => Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network('https://example.com/header.jpg', width: 100, height: 60),
          const Image(image: AssetImage('assets/images/flutter_logo.png'), width: 80, height: 80),
          Image.network('https://example.com/footer.png', width: 100, height: 40),
        ],
      ),
    ),
  );
}
