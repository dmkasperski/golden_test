#ifndef FLUTTER_PLUGIN_GOLDEN_TEST_PLUGIN_H_
#define FLUTTER_PLUGIN_GOLDEN_TEST_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace golden_test {

class GoldenTestPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GoldenTestPlugin();

  virtual ~GoldenTestPlugin();

  // Disallow copy and assign.
  GoldenTestPlugin(const GoldenTestPlugin&) = delete;
  GoldenTestPlugin& operator=(const GoldenTestPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace golden_test

#endif  // FLUTTER_PLUGIN_GOLDEN_TEST_PLUGIN_H_
