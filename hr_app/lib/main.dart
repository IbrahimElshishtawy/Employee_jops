import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/app_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle platform keyboard / accessibility glitches gracefully on Windows desktop
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('Attempted to send a key down event') ||
        msg.contains('RawKeyDownEvent') ||
        msg.contains('keysPressed') ||
        msg.contains('accessibility_bridge')) {
      return; // Ignore known desktop engine keyboard modifier assertion glitch
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('RawKeyDownEvent') ||
        msg.contains('keysPressed') ||
        msg.contains('accessibility_bridge')) {
      return true; // handled
    }
    return false;
  };

  final dependencies = await AppBootstrap.initialize();
  runApp(HrApp(dependencies: dependencies));
}
