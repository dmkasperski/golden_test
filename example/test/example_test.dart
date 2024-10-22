import 'package:flutter/material.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    name: 'Example',
    builder: (_) => Scaffold(
      body: Center(
        child: Container(
          height: 100,
          color: Colors.red,
          child: const Center(child: Text('Example')),
        ),
      ),
    ),
    supportMultipleDevices: true,
  );

  goldenTest(
    name: 'With appbar',
    builder: (_) => simulateRouteStack(
      Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Container(
            height: 100,
            color: Colors.red,
            child: const Center(child: Text('With appbar')),
          ),
        ),
      ),
    ),
    supportMultipleDevices: true,
  );
}
