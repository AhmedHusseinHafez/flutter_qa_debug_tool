// ignore_for_file: join_return_with_assignment

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qa_debug_tool/src/log_buffer.dart';

class NetworkLoggerScreen extends StatefulWidget {
  const NetworkLoggerScreen({super.key});

  @override
  State<NetworkLoggerScreen> createState() => _NetworkLoggerScreenState();
}

class _NetworkLoggerScreenState extends State<NetworkLoggerScreen> {
  static const int _maxPreviewChars = 12000;
  static const String _packageVersion = '1.1.0';

  final List<String> logs = [];
  List<String> filteredLogs = [];
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    logs.clear();
    logs.addAll(LogBuffer.fetch());
    filteredLogs = List.from(logs);

    searchCtrl.addListener(() {
      final q = searchCtrl.text.toLowerCase();
      setState(() {
        filteredLogs = logs.where((e) => e.toLowerCase().contains(q)).toList();
      });
    });
  }

  void addLog(String log) {
    setState(() {
      logs.insert(0, log);
      filteredLogs.insert(0, log);
    });
  }

  /// ✅ detect color correctly
  Color _detectColor(String log) {
    if (log.startsWith('-->')) return Colors.blue; // request
    if (log.startsWith('<-- ') && !log.contains('ERROR')) {
      return Colors.green; // response
    }
    if (log.contains('ERROR')) return Colors.red; // error
    return Colors.grey.shade800;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    // ✅ English UI only
    textDirection: TextDirection.ltr,
    child: Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network Logs'),
            SizedBox(height: 2),
            Text(
              'v$_packageVersion',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                LogBuffer.clear();
                logs.clear();
                filteredLogs.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          Expanded(child: _buildList()),
        ],
      ),
    ),
  );

  Widget _buildHeader() {
    final totalLogs = logs.length;
    final filteredCount = filteredLogs.length;
    final requests = logs.where((e) => e.startsWith('-->')).length;
    final responses = logs
        .where((e) => e.startsWith('<-- ') && !e.contains('ERROR'))
        .length;
    final errors = logs.where((e) => e.contains('ERROR')).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Network Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (searchCtrl.text.isNotEmpty)
                Chip(
                  label: Text('Filtered: $filteredCount'),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalLogs.toString(),
                  Colors.blue,
                  Icons.list_alt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Requests',
                  requests.toString(),
                  Colors.blue.shade300,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Responses',
                  responses.toString(),
                  Colors.green.shade300,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Errors',
                  errors.toString(),
                  Colors.red.shade300,
                  Icons.error_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    ),
  );

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.all(8),
    child: TextField(
      controller: searchCtrl,
      decoration: InputDecoration(
        hintText: 'Search logs...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _buildList() => ListView.builder(
    itemCount: filteredLogs.length,
    itemBuilder: (context, i) {
      final log = filteredLogs[i];
      final color = _detectColor(log);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          leading: CircleAvatar(radius: 6, backgroundColor: color),
          title: Text(
            log.split('\n').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          children: [
            _buildLogBody(log),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: log));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _buildLogBody(String log) {
    final header = log.split('\n').first;
    final headersStart = log.indexOf('Headers:');
    final dataStart = log.indexOf('Data:');

    String headersRaw = '';
    String bodyRaw = '';

    if (headersStart != -1 && dataStart != -1) {
      // Extract headers (between "Headers:" and "Data:")
      headersRaw = log.substring(headersStart + 8, dataStart).trim();
    }

    if (dataStart != -1) {
      bodyRaw = log.substring(dataStart + 5).trim();
    }

    final prettyHeaders = _tryPrettyHeaders(headersRaw);
    final isLargePayload = _isLargePayload(bodyRaw);
    final truncatedBody = _truncateForPreview(bodyRaw);
    final pretty = _tryPretty(truncatedBody);
    final hasHeaders = headersRaw.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Request/Response Header
          SelectableText(
            header,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          if (hasHeaders) ...[
            const SizedBox(height: 12),
            // ✅ Headers Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Headers',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              prettyHeaders,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.cyanAccent,
                fontSize: 12,
              ),
            ),
          ],
          if (bodyRaw.isNotEmpty) ...[
            const SizedBox(height: 12),
            // ✅ Data Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade900,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Data',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildJsonViewer(pretty, truncatedBody, isLargePayload),
          ],
        ],
      ),
    );
  }

  bool _isLargePayload(String raw) => raw.length > _maxPreviewChars;

  String _truncateForPreview(String raw) {
    if (raw.length <= _maxPreviewChars) return raw;
    final skipped = raw.length - _maxPreviewChars;
    return '${raw.substring(0, _maxPreviewChars)}\n... [truncated $skipped chars for preview]';
  }

  String _tryPrettyHeaders(String raw) {
    if (raw.isEmpty) return '';

    try {
      // Try to parse as JSON first
      final jsonObj = json.decode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObj);
    } catch (_) {
      // If not JSON, try to format as key-value pairs
      // Handle Map.toString() format: {key1: value1, key2: value2}
      if (raw.startsWith('{') && raw.endsWith('}')) {
        try {
          // Remove outer braces and split by comma
          final content = raw.substring(1, raw.length - 1).trim();
          if (content.isEmpty) return '{}';

          // Try to parse as JSON object
          final jsonObj = json.decode('{$content}');
          const encoder = JsonEncoder.withIndent('  ');
          return encoder.convert(jsonObj);
        } catch (_) {
          // Fallback: format manually
          return _formatHeadersManually(raw);
        }
      }
      return _formatHeadersManually(raw);
    }
  }

  // Simple formatting for non-JSON header strings
  String _formatHeadersManually(String raw) => raw
      .replaceAll(', ', ',\n')
      .replaceAll('{', '')
      .replaceAll('}', '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .join('\n');

  String _tryPretty(String raw) {
    if (raw.isEmpty) return '';

    // Check if it's FormData format
    if (raw.startsWith('FormData {')) {
      return raw; // Already formatted, return as is
    }

    try {
      final jsonObj = json.decode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObj);
    } catch (_) {
      return raw; // fallback to normal text
    }
  }

  Widget _buildJsonViewer(
    String prettyJson,
    String rawData,
    bool wasTruncated,
  ) {
    // Check if it's FormData format
    if (rawData.startsWith('FormData {')) {
      return _buildFormDataViewer(rawData);
    }

    // Avoid heavy parsing for very large payloads; show safe preview instead.
    if (wasTruncated) {
      return _buildLargePayloadPreview(rawData);
    }

    // First, try to parse as JSON
    try {
      final jsonObj = json.decode(rawData);
      // It's valid JSON, show with DevTools-style viewer
      return _JsonTreeViewer(jsonObj: jsonObj);
    } catch (_) {
      // Not valid JSON, try to convert Dart Map format to JSON
      try {
        final convertedJson = _convertDartMapToJson(rawData);
        final jsonObj = json.decode(convertedJson);
        return _JsonTreeViewer(jsonObj: jsonObj);
      } catch (_) {
        // Still not valid, show as plain text
        return SelectableText(
          prettyJson,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontSize: 13,
          ),
        );
      }
    }
  }

  Widget _buildLargePayloadPreview(String data) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade900,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Large payload previewed (truncated for stability). Use copy to inspect full data.',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(height: 6),
      SelectableText(
        data,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    ],
  );

  String _convertDartMapToJson(String dartMapString) {
    // Convert Dart Map format {key: value} to JSON format {"key": "value"}
    String result = dartMapString.trim();

    // Handle nested structures
    result = _convertDartMapRecursive(result);

    return result;
  }

  String _convertDartMapRecursive(String input) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < input.length) {
      final char = input[i];

      // Skip whitespace
      if (char == ' ' || char == '\n' || char == '\t') {
        i++;
        continue;
      }

      // Handle opening brace
      if (char == '{') {
        buffer.write('{');
        i++;

        // Find the matching closing brace
        int depth = 1;
        final int start = i;

        while (i < input.length && depth > 0) {
          if (input[i] == '{') depth++;
          if (input[i] == '}') depth--;
          if (depth > 0) i++;
        }

        if (depth == 0) {
          // Process the content inside braces
          final content = input.substring(start, i);
          final convertedContent = _convertMapContent(content);
          buffer.write(convertedContent);
          buffer.write('}');
          i++;
        }
        continue;
      }

      // Handle opening bracket (arrays)
      if (char == '[') {
        buffer.write('[');
        i++;

        int depth = 1;
        final int start = i;

        while (i < input.length && depth > 0) {
          if (input[i] == '[') depth++;
          if (input[i] == ']') depth--;
          if (depth > 0) i++;
        }

        if (depth == 0) {
          final content = input.substring(start, i);
          final convertedContent = _convertArrayContent(content);
          buffer.write(convertedContent);
          buffer.write(']');
          i++;
        }
        continue;
      }

      buffer.write(char);
      i++;
    }

    return buffer.toString();
  }

  String _convertMapContent(String content) {
    if (content.trim().isEmpty) return '';

    final parts = <String>[];
    int i = 0;
    int depth = 0;
    int start = 0;

    while (i < content.length) {
      final char = content[i];

      if (char == '{' || char == '[') depth++;
      if (char == '}' || char == ']') depth--;

      if (char == ',' && depth == 0) {
        parts.add(content.substring(start, i).trim());
        start = i + 1;
      }

      i++;
    }

    // Add the last part
    if (start < content.length) {
      parts.add(content.substring(start).trim());
    }

    return parts.map(_convertKeyValue).join(', ');
  }

  String _convertArrayContent(String content) {
    if (content.trim().isEmpty) return '';

    final parts = <String>[];
    int i = 0;
    int depth = 0;
    int start = 0;

    while (i < content.length) {
      final char = content[i];

      if (char == '{' || char == '[') depth++;
      if (char == '}' || char == ']') depth--;

      if (char == ',' && depth == 0) {
        parts.add(content.substring(start, i).trim());
        start = i + 1;
      }

      i++;
    }

    if (start < content.length) {
      parts.add(content.substring(start).trim());
    }

    return parts.map(_convertValue).join(', ');
  }

  String _convertKeyValue(String keyValue) {
    final colonIndex = keyValue.indexOf(':');
    if (colonIndex == -1) return keyValue;

    final key = keyValue.substring(0, colonIndex).trim();
    final value = keyValue.substring(colonIndex + 1).trim();

    // Convert key to JSON string (add quotes if not already quoted)
    String jsonKey;
    if (key.startsWith('"') && key.endsWith('"')) {
      jsonKey = key;
    } else {
      jsonKey = '"$key"';
    }

    // Convert value
    final jsonValue = _convertValue(value);

    return '$jsonKey: $jsonValue';
  }

  String _convertValue(String value) {
    // ignore: parameter_assignments
    value = value.trim();

    if (value.isEmpty) return 'null';

    // Already a JSON string
    if (value.startsWith('"') && value.endsWith('"')) {
      return value;
    }

    // Null
    if (value == 'null') {
      return 'null';
    }

    // Boolean
    if (value == 'true' || value == 'false') {
      return value;
    }

    // Number
    if (RegExp(r'^-?\d+(\.\d+)?([eE][+-]?\d+)?$').hasMatch(value)) {
      return value;
    }

    // Object or array
    if (value.startsWith('{') || value.startsWith('[')) {
      return _convertDartMapRecursive(value);
    }

    // String value - add quotes and escape
    return '"${_escapeJsonString(value)}"';
  }

  String _escapeJsonString(String str) => str
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  Widget _buildFormDataViewer(String formDataString) {
    final lines = formDataString.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) continue;

      TextStyle style;

      if (trimmedLine == 'FormData {' || trimmedLine == '}') {
        // Braces
        style = const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        );
      } else if (trimmedLine.endsWith(':')) {
        // Section headers (Fields:, Files:)
        style = const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.orangeAccent,
          fontWeight: FontWeight.bold,
        );
      } else if (trimmedLine.contains(':') && !trimmedLine.contains('{')) {
        // Key-value pairs
        final parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();

          widgets.add(
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${' ' * (line.length - trimmedLine.length)}$key: ',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
          continue;
        }
        style = const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.white,
        );
      } else {
        // Default text
        style = const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.white,
        );
      }

      widgets.add(SelectableText(line, style: style));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

// DevTools-style JSON Tree Viewer
class _JsonTreeViewer extends StatefulWidget {
  const _JsonTreeViewer({required this.jsonObj, this.level = 0, this.jsonKey});
  final dynamic jsonObj;
  final int level;
  final String? jsonKey;

  @override
  State<_JsonTreeViewer> createState() => _JsonTreeViewerState();
}

class _JsonTreeViewerState extends State<_JsonTreeViewer> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final obj = widget.jsonObj;
    final level = widget.level;
    final key = widget.jsonKey;

    if (obj is Map) {
      return _buildMap(obj, level, key);
    } else if (obj is List) {
      return _buildList(obj, level, key);
    } else {
      return _buildPrimitive(obj, level, key);
    }
  }

  Widget _buildMap(Map map, int level, String? key) {
    final indent = '  ' * level;
    final isEmpty = map.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (key != null) ...[
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$indent"$key": ',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isEmpty)
                          const TextSpan(
                            text: '{}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          TextSpan(
                            text: _isExpanded ? '{' : '{...}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SelectableText(
                    isEmpty ? '{}' : (_isExpanded ? '{' : '{...}'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_isExpanded && !isEmpty) ...[
          ...map.entries.map((entry) {
            final isLast = entry == map.entries.last;
            return Padding(
              padding: EdgeInsets.only(left: (level + 1) * 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JsonTreeViewer(
                    jsonObj: entry.value,
                    level: level + 1,
                    jsonKey: entry.key.toString(),
                  ),
                  if (!isLast)
                    const SelectableText(
                      ',',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            );
          }),
          SelectableText(
            '$indent}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildList(List list, int level, String? key) {
    final indent = '  ' * level;
    final isEmpty = list.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (key != null) ...[
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$indent"$key": ',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isEmpty)
                          const TextSpan(
                            text: '[]',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          TextSpan(
                            text: _isExpanded ? '[' : '[...]',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SelectableText(
                    isEmpty ? '[]' : (_isExpanded ? '[' : '[...]'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_isExpanded && !isEmpty) ...[
          ...list.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final isLast = index == list.length - 1;
            return Padding(
              padding: EdgeInsets.only(left: (level + 1) * 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JsonTreeViewer(jsonObj: value, level: level + 1),
                  if (!isLast)
                    const SelectableText(
                      ',',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            );
          }),
          SelectableText(
            '$indent]',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimitive(dynamic value, int level, String? key) {
    final indent = '  ' * level;
    Color valueColor;
    String valueText;

    if (value == null) {
      valueColor = Colors.redAccent;
      valueText = 'null';
    } else if (value is String) {
      valueColor = Colors.greenAccent;
      valueText = '"$value"';
    } else if (value is num) {
      valueColor = Colors.lightBlueAccent;
      valueText = value.toString();
    } else if (value is bool) {
      valueColor = Colors.orangeAccent;
      valueText = value.toString();
    } else {
      valueColor = Colors.white;
      valueText = value.toString();
    }

    return SelectableText.rich(
      TextSpan(
        children: [
          if (key != null)
            TextSpan(
              text: '$indent"$key": ',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            TextSpan(text: indent),
          TextSpan(
            text: valueText,
            style: TextStyle(color: valueColor),
          ),
        ],
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
    );
  }
}
