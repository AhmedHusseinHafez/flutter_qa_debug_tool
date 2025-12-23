import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ScreenLoggerInterceptor extends Interceptor {
  ScreenLoggerInterceptor({required this.onLog});
  final void Function(String) onLog;

  static const int _maxPayloadLength = 20000;
  static const int _isolateJsonThreshold = 256 * 1024; // 256 KB

  String _truncate(String value) {
    if (value.length <= _maxPayloadLength) return value;
    final truncated = value.substring(0, _maxPayloadLength);
    final skipped = value.length - _maxPayloadLength;
    return '$truncated\n... [truncated $skipped chars]';
  }

  Future<String> _formatData(dynamic data) async {
    if (data == null) return 'null';
    try {
      // Handle FormData objects
      if (data is FormData) {
        return _formatFormData(data);
      }
      // Encode as compact JSON for Map/List to reduce size
      if (data is Map || data is List) {
        final approxSize = data.toString().length;
        if (approxSize > _isolateJsonThreshold) {
          final encoded = await compute(_encodeJsonCompact, data);
          return _truncate(encoded);
        }
        final encoded = json.encode(data);
        return _truncate(encoded);
      }
      // If it's already a string, try to parse and re-encode for pretty printing
      if (data is String) {
        if (data.length > _isolateJsonThreshold) {
          try {
            final encoded = await compute(_normalizeJsonString, data);
            return _truncate(encoded);
          } catch (_) {
            return _truncate(data);
          }
        }
        try {
          final parsed = json.decode(data);
          final encoded = json.encode(parsed);
          return _truncate(encoded);
        } catch (_) {
          // Not JSON, return as is
          return _truncate(data);
        }
      }
      return _truncate(data.toString());
    } catch (_) {
      return _truncate(data.toString());
    }
  }

  String _formatFormData(FormData formData) {
    final buffer = StringBuffer();
    buffer.writeln('FormData {');

    // Handle fields
    if (formData.fields.isNotEmpty) {
      buffer.writeln('  Fields:');
      for (final field in formData.fields) {
        buffer.writeln('    ${field.key}: "${field.value}"');
      }
    }

    // Handle files
    if (formData.files.isNotEmpty) {
      buffer.writeln('  Files:');
      for (final file in formData.files) {
        final multipartFile = file.value;
        buffer.writeln('    ${file.key}: {');
        buffer.writeln(
          '      filename: "${multipartFile.filename ?? 'unknown'}"',
        );
        buffer.writeln(
          '      contentType: "${multipartFile.contentType ?? 'unknown'}"',
        );
        buffer.writeln('      length: ${multipartFile.length} bytes');
        buffer.writeln('    }');
      }
    }

    buffer.write('}');
    return buffer.toString();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final data = await _formatData(options.data);
    final log =
        '--> ${options.method} ${options.uri}\nHeaders: ${options.headers}\nData: $data';
    onLog(log);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final data = await _formatData(response.data);
    final log =
        '<-- ${response.statusCode} ${response.requestOptions.uri}\nData: $data';
    onLog(log);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode ?? 'NO_STATUS';
    final rawData = err.response?.data ?? '';
    final data = await _formatData(rawData);
    final log =
        '''
<-- ERROR $status ${err.requestOptions.uri}
Type: ${err.type}
Message: ${err.message}
Data: $data
''';
    onLog(log);
    super.onError(err, handler);
  }
}

// Top-level helpers for compute() to avoid blocking the UI isolate
String _encodeJsonCompact(dynamic data) => json.encode(data);

String _normalizeJsonString(String data) {
  final parsed = json.decode(data);
  return json.encode(parsed);
}
