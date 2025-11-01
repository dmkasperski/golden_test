import 'package:flutter/material.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    'Example',
    builder: (_) => Scaffold(
      body: Center(
        child: Container(
          height: 100,
          color: Colors.red,
          child: const Center(child: Text('Centered')),
        ),
      ),
    ),
    supportMultipleDevices: true,
  );

  goldenTest(
    'With appbar',
    builder: (_) => simulateRouteStack(
      Scaffold(
        appBar: AppBar(
          title: Text('App Bar Title'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Container(
            height: 100,
            color: Colors.red,
            child: const Center(child: Text('Centered with AppBar')),
          ),
        ),
      ),
    ),
    supportMultipleDevices: true,
  );
}
