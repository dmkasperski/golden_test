#include "include/golden_test/golden_test_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "golden_test_plugin.h"

void GoldenTestPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  golden_test::GoldenTestPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
