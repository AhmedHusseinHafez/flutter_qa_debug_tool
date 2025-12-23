class LogBuffer {
  LogBuffer._();

  /// Maximum number of log entries to retain in memory.
  static const int maxEntries = 200;

  /// Maximum characters kept per log entry to prevent memory bloat.
  static const int maxCharsPerEntry = 20000;

  static final List<String> _pendingLogs = <String>[];

  /// Add a log entry while enforcing size limits to keep memory stable.
  static void add(String log) {
    final normalized = _truncate(log);
    _pendingLogs.insert(0, normalized);

    if (_pendingLogs.length > maxEntries) {
      _pendingLogs.removeRange(maxEntries, _pendingLogs.length);
    }
  }

  /// Return a copy of the buffered logs (newest first).
  static List<String> fetch() => List<String>.unmodifiable(_pendingLogs);

  static void clear() {
    _pendingLogs.clear();
  }

  static String _truncate(String value) {
    if (value.length <= maxCharsPerEntry) return value;

    final kept = value.substring(0, maxCharsPerEntry);
    final skipped = value.length - maxCharsPerEntry;
    return '$kept\n... [truncated $skipped chars]';
  }
}
