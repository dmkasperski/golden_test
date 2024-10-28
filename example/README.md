# golden_test_example

Demonstrates how to use the golden_test plugin.

```dart
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
  );
```