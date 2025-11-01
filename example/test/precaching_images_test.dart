import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:golden_test/golden_test.dart';

final red100x100PixelsImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAApElEQVR42u3RAQ0AAAjD'
  'MO5fNCCDkC5z0HTVrisFCBABASIgQAQEiIAAAQJEQIAICBABASIgQAREQIAICBABASIg'
  'QAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQARE'
  'QIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAQECBAgAgJEQIAIyPcGFY7H'
  'nV2aPXoAAAAASUVORK5CYII=',
);

void main() {
  goldenTest(
    'Image from asset should be displayed',
    builder: (_) => Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const Image(
            image: AssetImage('assets/images/flutter_logo.png'),
            height: 100,
            width: 100,
          ),
          FadeInImage(
            image: AssetImage('assets/images/flutter_logo.png'),
            placeholder: MemoryImage(red100x100PixelsImage),
            height: 100,
            width: 100,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/flutter_logo.png'),
              ),
            ),
            child: SizedBox(width: 100, height: 100),
          ),
        ],
      ),
    ),
    supportMultipleDevices: true,
  );
}
