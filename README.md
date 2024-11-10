- [Introduction](#introduction)
  - [Installation](#installation)
  - [Example](#example)
  - [Device Configuration](#device-configuration)
    - [Supported Devices](#supported-devices)
  - [Localized Goldens](#localized-goldens)
    - [Localization Delegates](#localization-delegates)
    - [Using intl](#using-intl)
    - [Custom Fonts](#custom-fonts)
  - [Setup Theme](#setup-theme)
    - [Dark mode](#dark-mode)
  - [Global config](#global-config)
  - [Difference tolerance](#difference-tolerance)

# golden_test

<a name="introduction"></a>
### Introduction
Golden Test is a Flutter plugin for writing golden tests.

Supported Features:
1. Multiple device support
2. Dark mode support
3. Localized Goldens

<a name="installation"></a>
### Installation

```yaml
    dev_dependencies:
        golden_test: [latest-version]
```
<a name="example"></a>
### Example
```dart
    goldenTest(
      name: 'Example Page',
      builder: (_) => ExamplePage(),
    );
```

<a name="device-configuration"></a>
### Device Configuration
To run golden tests across multiple devices, this project defines a set of pre-configured devices for testing. You can prepare your own configuration globally and if needed override it for specific test. By default, tests are run on a single device, iPhone 15 Pro, but additional devices are available for testing. You can configure a specific test to run on multiple devices using the supportedDevices parameter in goldenTest.

Example
To specify devices for a particular test:

```dart
    goldenTest(
        name: 'Example Page',
        supportedDevices: [Device.iphone15Pro(), Device.pixel9ProXL()],
        builder: (_) => ExamplePage(),
    );
```

To specify devices for all goldenTest you run across the project, you can override configuration:

```dart
List<Device> goldenTestSupportedDevices = [
    // list of devices
    ];
```

and each Golden Test needs to enable multi device support:
```dart
    goldenTest(
        name: 'Example Page',
        supportMultipleDevices: true,
        builder: (_) => ExamplePage(),
    );
```

<a name="supported-devices"></a>
#### Supported Devices
The following devices are configured for testing, but you can always create your custom one using the `Device` class.

```dart
    Device.noInsets() - a baseline device without insets
    Device.iphone15Pro() - simulates the iPhone 15 Pro
    Device.pixel9ProXL() - simulates the Pixel 9 Pro XL
    Device.ipadPro12() - simulates the iPad Pro 12
    Device.browser() - simulates a generic web browser
```

<a name="localized-goldens"></a>
## Localized Goldens
Golden tests support multiple locales to verify the app's appearance and behavior across different languages. The list of supported locales and localization delegates can be modified based on the app's specific needs.

By default plugin is set to support `en_US` locales. To add more locales supported for all tests modify the `goldenTestSupportedLocales` list i.e:

```dart
  goldenTestSupportedLocales = [
    const Locale('pl'),
    const Locale('en'),
  ];
```

or specify locales in specific tests you want to run it for multiple locales.

```dart
    goldenTest(
      name: 'Example Page',
      builder: (_) => ExamplePage(),
      supportedLocales: [
        const Locale('pl'),
        const Locale('en'),
        ],
    );
```

#### Localization Delegates
To support additional localizations, include localization delegates based on the tool you use for localizations in the goldenTestLocalizationsDelegates list:

```dart
    goldenTestLocalizationsDelegates = [
        YourAppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
    ];
```
or per specific test:

```dart
    goldenTest(
        name: 'Example Page',
        builder: (_) => ExamplePage(),
        supportedLocales: [
            const Locale('pl'),
            const Locale('en'),
        ],
        localizationsDelegates: [
            YourAppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
        ],
    );
```
<a name="using-intl"></a>
#### Using intl
If your project supports localization using the [intl](https://pub.dev/packages/intl) package and your default locales are not `en_US` or you want to support multiple localizations you need to provide addtional configuration especially for intl. It's because intl has hardcoded system locales (`Intl.systemLocales`) to `en_US` while it's need to be changed per test. You can do it adding this code to your flutter config file:

```dart
    globalSetup = (locale) async => Intl.defaultLocale = locale.languageCode;
```


<a name="custom-fonts"></a>
#### Custom fonts
If your project support any custom font you need to register it and load it for all of its associated assets into the Flutter engine, making the font available to the current application. Every font family need to be loaded once per font loader.

Example code:

```dart
    Future<void> setupFonts() async {
        TestWidgetsFlutterBinding.ensureInitialized();

        await (FontLoader('Roboto')..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
    }
```

If your project use [Google Fonts](https://pub.dev/packages/google_fonts) package you need to find .otf or .ttr file for the font you're using and provide it directly as a asset into your application.


<a name="setup-theme"></a>
# Setup Theme
To setup themes for you app you need to set them using the configuration:
```dart
    goldenTestThemeInTests = yourThemeData;
    goldenTestDarkThemeInTests = yourThemeDataDark;
```

If theme is not set it will use basic `ThemeData()` set in default configuration.

<a name="dark-mode"></a>
## Dark Theme
Golden Test allows you to run tests for both light and dark modes, enabling visual testing of your app across different theme settings. By default tests run for both themes. To disable dark mode tests, modify the `goldenTestSupportedThemes` list:

```dart
    goldenTestSupportedThemes = [Brightness.light]
```

You can also configure each test you run to specify supported themes:
```dart
    goldenTest(
        name: 'Example Page',
        builder: (_) => ExamplePage(),
        supportedThemes: [Brightness.light, Brightness.dark],
    );
```

<a name="global-config"></a>
## Global Setup Callback
The globalSetup callback allows you to define project-specific configurations, such as disabling animations or setting a default locale for tests.

```dart
    globalSetup = (_) async => duringTestExecution = false;
```

<a name="difference-tolerance"></a>
## Difference Tolerance
Difference tolerance for golden tests can help manage acceptable visual differences between the reference images and the current UI output. This is particularly useful for allowing small variations, such as those caused by anti-aliasing or minor platform rendering differences.

Example - to achieve tolerance of 0.01% call:
```dart
    goldenTestDifferenceTolerance(0.01);
```
