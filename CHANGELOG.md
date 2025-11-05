## 0.1.6
1. **New Feature**: Added `subdirectory` parameter to `goldenTest` for organizing golden files into custom subdirectories
   - Allows per-test configuration of golden file organization
   - Useful for managing multiple apps with different design tokens
   - Supports nested subdirectories (e.g., `'design_system/v2'`)
   - Path structure: `goldens/[subdirectory]/locale/theme/[device]/name.png`

## 0.1.5
1. Refactor device configuration system to support three distinct configuration levels:
   - **New**: Added `goldenTestDefaultDevices` for setting global default device(s)
   - **Improved**: `goldenTestSupportedDevices` now exclusively for multi-device testing
   - **Changed**: `supportedDevices` parameter is now nullable, enabling proper configuration hierarchy
   - **Enhanced**: Device selection logic now follows clear priority: per-test override > multi-device mode > global default
   - **Fixed**: Golden file paths now intelligently include device names only when testing multiple devices 
   
    This change makes device configuration more intuitive and eliminates the need to pass `supportMultipleDevices: true` just to use a globally-defined single device.
2. Improved formatting
3. Updated dependencies
4. Updated example project
5. Updated documentation
6. Drop deprecated .withOpacity

## 0.1.4
Fix directory for generating failure screenshots.

## 0.1.3
Add option to precache assets.

## 0.1.2
Add option to set difference tolerance at which tests are considered failing.

## 0.1.1
Add read.me to example project.

## 0.1.0

Initial release of goldenTest method which helps writing Golden Tests very easily by pumping Flutter Widgets.

Features:
1. `goldenTest` - utility method for generating screenshots
2. Supporting multiple locales.
3. Supporting multiple localizations.
4. Supporting light and dark mode.
