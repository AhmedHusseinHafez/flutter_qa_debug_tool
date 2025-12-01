import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:flutter_qa_debug_tool/src/log_buffer.dart';
import 'package:flutter_qa_debug_tool/src/network_logger_screen.dart';
import 'package:flutter_qa_debug_tool/src/screen_logger_interceptor.dart';

export 'package:flutter_qa_debug_tool/src/log_buffer.dart';
export 'package:flutter_qa_debug_tool/src/network_logger_screen.dart';
export 'package:flutter_qa_debug_tool/src/screen_logger_interceptor.dart';

/// Public API for network debugging in Flutter apps.
///
/// This package provides a simple way to log and inspect network requests
/// and responses made with Dio. It includes a beautiful UI screen to view
/// logs with search, filtering, and JSON tree viewing capabilities.
class NetworkDebugger {
  const NetworkDebugger._();

  /// Attach the screen logger interceptor to a given [Dio] instance.
  ///
  /// Typically called once when configuring networking:
  ///
  /// ```dart
  /// final dio = Dio();
  /// NetworkDebugger.attachToDio(dio);
  /// ```
  static void attachToDio(Dio dio, {bool enabled = true}) {
    if (!enabled) return;

    dio.interceptors.add(ScreenLoggerInterceptor(onLog: LogBuffer.add));
  }

  /// Open the network logger screen using the provided [BuildContext].
  ///
  /// Can be called from anywhere you have a [BuildContext]:
  ///
  /// ```dart
  /// NetworkDebugger.open(context);
  /// ```
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const NetworkLoggerScreen()));

  /// A ready-to-use floating action button that opens the logger screen.
  ///
  /// Example:
  /// ```dart
  /// Scaffold(
  ///   floatingActionButton: NetworkDebugger.fab(),
  ///   body: ...
  /// )
  /// ```
  static Widget fab({Key? key}) => Builder(
    builder: (context) => FloatingActionButton(
      key: key,
      onPressed: () => open(context),
      mini: true,
      backgroundColor: Colors.black87,
      child: const Icon(Icons.network_check, color: Colors.white),
    ),
  );
}
