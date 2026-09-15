import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:golden_test/golden_test.dart';

/// A 1x1 transparent PNG, so `FadeInImage` needs no placeholder asset.
final _transparentPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII=',
);

void main() {
  // Every route below paints a `NetworkImage`, so one stub covers them all.
  goldenTest(
    name: 'Network image stub',
    supportedDevices: [const Device.noInsets()],
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light, Brightness.dark],
    builder: (_) => Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Image.network'),
            Image.network(
              'https://example.com/image.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 12),
            const Text('FadeInImage'),
            FadeInImage(
              placeholder: MemoryImage(_transparentPixel),
              image: const NetworkImage('https://example.com/fade.png'),
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 12),
            const Text('DecorationImage'),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://example.com/decoration.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Cropped (BoxFit.cover, non-square)'),
            Image.network(
              'https://example.com/wide.png',
              width: 160,
              height: 48,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    ),
  );
}
