import 'dart:convert';
import 'package:dio/dio.dart';

class ScreenLoggerInterceptor extends Interceptor {
  ScreenLoggerInterceptor({required this.onLog});
  final void Function(String) onLog;

  String _formatData(dynamic data) {
    if (data == null) return 'null';
    try {
      // Handle FormData objects
      if (data is FormData) {
        return _formatFormData(data);
      }
      // Try to encode as JSON if it's a Map or List
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      }
      // If it's already a string, try to parse and re-encode for pretty printing
      if (data is String) {
        try {
          final parsed = json.decode(data);
          const encoder = JsonEncoder.withIndent('  ');
          return encoder.convert(parsed);
        } catch (_) {
          // Not JSON, return as is
          return data;
        }
      }
      return data.toString();
    } catch (_) {
      return data.toString();
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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final log =
        '--> ${options.method} ${options.uri}\nHeaders: ${options.headers}\nData: ${_formatData(options.data)}';
    onLog(log);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final log =
        '<-- ${response.statusCode} ${response.requestOptions.uri}\nData: ${_formatData(response.data)}';
    onLog(log);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode ?? 'NO_STATUS';
    final data = err.response?.data ?? '';
    final log =
        '''
<-- ERROR $status ${err.requestOptions.uri}
Type: ${err.type}
Message: ${err.message}
Data: ${_formatData(data)}
''';
    onLog(log);
    super.onError(err, handler);
  }
}
